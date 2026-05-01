# ─────────────────────────────────────────────
# VPC Network
# ─────────────────────────────────────────────

resource "google_compute_network" "educates" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "educates" {
  name          = var.subnet_name
  network       = google_compute_network.educates.id
  region        = var.region
  project       = var.project_id
  ip_cidr_range = var.subnet_cidr

  # Secondary ranges required for GKE alias IPs (VPC-native networking)
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = true
}

# ─────────────────────────────────────────────
# Static external IP for the Contour ingress LB
# ─────────────────────────────────────────────

resource "google_compute_address" "ingress" {
  name    = "${var.cluster_name}-ingress-ip"
  region  = var.region
  project = var.project_id

  labels = var.labels
}

# ─────────────────────────────────────────────
# GKE Standard Cluster
#
# Educates requirements (from docs.educates.dev):
#   - Standard cluster (NOT Autopilot) — Kyverno needs privileged containers
#   - NetworkPolicy enabled           — required by Kyverno
#   - Workload Identity               — required for GKE provider
#   - Container-Optimized OS + containerd (COS_CONTAINERD)
#   - ≥ 4 vCPU / 16 GB RAM per node (n2-standard-4 default)
#   - ≥ 3 worker nodes
# ─────────────────────────────────────────────

resource "google_container_cluster" "educates" {
  name     = var.cluster_name
  location = var.zone
  project  = var.project_id

  # Remove the default node pool immediately; we manage our own below.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.educates.id
  subnetwork = google_compute_subnetwork.educates.id

  # VPC-native (alias IP) networking — required for secondary ranges
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Dataplane V2 — enforces NetworkPolicy natively via eBPF.
  # Faster than Calico (no DaemonSet rollout) and required by Educates/Kyverno.
  datapath_provider = "ADVANCED_DATAPATH"

  # Workload Identity — required for GKE
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  # Minimum master version (empty string defers to the release channel default)
  min_master_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  # Release channel — REGULAR keeps patch versions stable between applies
  release_channel {
    channel = var.kubernetes_version != "" ? "UNSPECIFIED" : "REGULAR"
  }

  # Allow deletion without protection (suitable for ephemeral workshop environments)
  deletion_protection = false

  resource_labels = var.labels
}

# ─────────────────────────────────────────────
# Dedicated Node Pool
# ─────────────────────────────────────────────

resource "google_container_node_pool" "educates_nodes" {
  name     = "${var.cluster_name}-nodes"
  cluster  = google_container_cluster.educates.id
  location = var.zone
  project  = var.project_id

  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type

    # Container-Optimized OS with containerd — required by Educates on GKE
    image_type = "COS_CONTAINERD"

    # Workload Identity on nodes
    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = var.labels

    # Integrity monitoring kept on (low overhead); secure boot disabled —
    # it adds per-node boot verification that significantly slows pool creation.
    shielded_instance_config {
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# ─────────────────────────────────────────────
# Cloud DNS managed zone
#
# Covers the ingress_domain subdomain only (e.g. workshops.example.com).
# Your root domain stays in Cloudflare — you only need to add NS records
# in Cloudflare that delegate this subdomain to Google Cloud DNS.
#
# After apply, run:
#   terraform output dns_name_servers
# then add those four NS records for the subdomain in Cloudflare.
# ─────────────────────────────────────────────

resource "google_dns_managed_zone" "educates" {
  name        = var.cloud_dns_zone
  dns_name    = "${var.ingress_domain}."
  description = "Educates workshop ingress domain — managed by Terraform"
  project     = var.project_id

  labels = var.labels
}

# ─────────────────────────────────────────────
# Workload Identity — Service Accounts for Educates
#
# Educates requires two GSAs with DNS admin rights so that
# external-dns and cert-manager can manage Cloud DNS records:
#   external-dns  → manages DNS A records for workshop ingress hostnames
#   cert-manager  → performs ACME DNS-01 challenges for TLS certificates
#
# Each GSA is bound to the Kubernetes Service Account (KSA) that
# Educates creates in the cluster, following the standard Workload
# Identity pattern: KSA → GSA via iam.workloadIdentityUser.
# ─────────────────────────────────────────────

resource "google_service_account" "external_dns" {
  account_id   = "${var.cluster_name}-ext-dns"
  display_name = "Educates external-dns (${var.cluster_name})"
  project      = var.project_id
}

resource "google_service_account" "cert_manager" {
  account_id   = "${var.cluster_name}-cert-mgr"
  display_name = "Educates cert-manager (${var.cluster_name})"
  project      = var.project_id
}

# Grant both GSAs DNS admin so they can create/update Cloud DNS records
resource "google_project_iam_member" "external_dns_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_project_iam_member" "cert_manager_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager.email}"
}

# Workload Identity bindings — allow the KSAs created by Educates to
# impersonate the GSAs above.
#
# KSA namespaces/names used by Educates:
#   external-dns  → namespace: external-dns,  serviceaccount: external-dns
#   cert-manager  → namespace: cert-manager,  serviceaccount: cert-manager
resource "google_service_account_iam_member" "external_dns_wi" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"

  depends_on = [google_container_cluster.educates]
}

resource "google_service_account_iam_member" "cert_manager_wi" {
  service_account_id = google_service_account.cert_manager.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"

  depends_on = [google_container_cluster.educates]
}

# ─────────────────────────────────────────────
# Educates platform config file
#
# Written to the working directory after apply.
# Pass it to: educates deploy-platform --config educates-config.yaml
# ─────────────────────────────────────────────

resource "local_file" "educates_config" {
  filename        = "${path.module}/educates-config.yaml"
  file_permission = "0644"

  content = <<-YAML
    # Educates platform configuration for GKE
    # Generated by Terraform — do not edit manually.
    #
    # Usage:
    #   gcloud container clusters get-credentials ${google_container_cluster.educates.name} \
    #     --zone ${var.zone} --project ${var.project_id}
    #   educates deploy-platform --config educates-config.yaml

    clusterInfrastructure:
      provider: "gke"
      gcp:
        project: "${var.project_id}"
        cloudDNS:
          zone: "${var.cloud_dns_zone}"
        workloadIdentity:
          external-dns: "${google_service_account.external_dns.email}"
          cert-manager: "${google_service_account.cert_manager.email}"

    clusterIngress:
      domain: "${var.ingress_domain}"
      # Point *.${var.ingress_domain} at the static IP below before running deploy-platform.
      # Static IP: ${google_compute_address.ingress.address}

    clusterPackages:
      contour:
        enabled: true
        settings:
          infrastructure:
            loadBalancerIP: "${google_compute_address.ingress.address}"
      cert-manager:
        enabled: true
      kyverno:
        enabled: true
      educates:
        enabled: true

  YAML
}
