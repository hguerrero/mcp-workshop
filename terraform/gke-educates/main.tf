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
# Data sources
# ─────────────────────────────────────────────

data "google_client_config" "default" {}

# Resolves the latest available patch version for the requested minor version
# (e.g. "1.33" → "1.33.2-gke.1200"). Avoids version drift from hardcoded strings.
data "google_container_engine_versions" "gke_versions" {
  project        = var.project_id
  location       = var.zone
  version_prefix = "${var.kubernetes_version}."
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

  # Calico network policy — required by Educates.
  # Note: adds ~10-15 min to node pool creation while Calico DaemonSet rolls out.
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Workload Identity — required for GKE
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  # Use the latest patch in the requested minor version
  min_master_version = data.google_container_engine_versions.gke_versions.latest_master_version

  release_channel {
    channel = "REGULAR"
  }

  # Disable GKE's built-in HTTP(S) LB addon — Contour manages ingress instead.
  # network_policy_config must be explicitly enabled here when Calico is used,
  # otherwise GKE rejects the node pool update with a 400.
  addons_config {
    http_load_balancing {
      disabled = true
    }
    network_policy_config {
      disabled = false
    }
  }

  # Allow deletion without protection (suitable for ephemeral workshop environments)
  deletion_protection = false

  resource_labels = var.labels
}

# ─────────────────────────────────────────────
# Dedicated node service account
#
# Using a dedicated SA instead of the default compute SA limits the blast
# radius if a node is compromised. OAuth scopes further restrict what
# the node processes can call on behalf of the SA.
# ─────────────────────────────────────────────

resource "google_service_account" "node_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE node service account for ${var.cluster_name}"
  project      = var.project_id
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

    service_account = google_service_account.node_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
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
          zone: "${var.ingress_domain}"
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

    websiteStyling:
      workshopDashboard:
        style: |
          .bg-primary {
            background-color: #000f06 !important;
          }
          /* Override for all nav-pills */
          .nav-pills {
            --bs-nav-pills-link-active-bg: #ccff00; /* Your custom color */
            --bs-nav-pills-link-active-color: #000f06; /* Optional: Change text color too */
          }
      workshopInstructions:
        style: |
          .bg-primary {
            background-color: #000f06 !important;
          }
      trainingPortal:
        style: |
          /* Normal state */
          .btn-primary {
            color: #000f06;
            background-color: #ccff00;
            border-color: #ccff00;
          }
          /* Hover/Active states */
          .btn-primary:hover,
          .btn-primary:focus,
          .btn-primary:active {
            color: #000f06;
            background-color: #b7e500; /* Darker shade */
            border-color: #b7e500;
          }

  YAML
}

# ─────────────────────────────────────────────
# Kubeconfig file
#
# Written to the module directory after apply.
# Uses gke-gcloud-auth-plugin for token refresh — required for kubectl ≥ 1.26.
# ─────────────────────────────────────────────

locals {
  kubeconfig_filename = "${path.module}/kubeconfig-${var.cluster_name}.yaml"

  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = var.cluster_name
    clusters = [{
      name = var.cluster_name
      cluster = {
        certificate-authority-data = google_container_cluster.educates.master_auth[0].cluster_ca_certificate
        server                     = "https://${google_container_cluster.educates.endpoint}"
      }
    }]
    contexts = [{
      name = var.cluster_name
      context = {
        cluster = var.cluster_name
        user    = var.cluster_name
      }
    }]
    users = [{
      name = var.cluster_name
      user = {
        exec = {
          apiVersion      = "client.authentication.k8s.io/v1beta1"
          command         = "gke-gcloud-auth-plugin"
          installHint     = "Install gke-gcloud-auth-plugin: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin"
          interactiveMode = "IfAvailable"
        }
      }
    }]
  })
}

resource "local_file" "kubeconfig" {
  content         = local.kubeconfig
  filename        = local.kubeconfig_filename
  file_permission = "0600"

  depends_on = [google_container_cluster.educates]
}
