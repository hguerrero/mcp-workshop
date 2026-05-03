# terraform/gke-educates

Terraform module that provisions GKE infrastructure for running the [Educates](https://docs.educates.dev) workshop platform. After `terraform apply` you have a ready-to-use GKE cluster and a generated `educates-config.yaml` you can pass directly to `educates deploy-platform`.

This module is independent from the [`terraform/kong-serverless-gateways/`](../kong-serverless-gateways/) module, which provisions the per-student Konnect environments.

---

## What It Creates

| Resource | Description |
|---|---|
| `google_compute_network` | Dedicated VPC for the cluster |
| `google_compute_subnetwork` | Subnet with secondary ranges for pod and service IPs |
| `google_compute_address` | Static external IP for the Contour ingress load balancer |
| `google_container_cluster` | GKE Standard cluster (not Autopilot) with Calico NetworkPolicy and Workload Identity |
| `google_container_node_pool` | Worker node pool — defaults to 1 × `n2-standard-4` with COS_CONTAINERD |
| `google_service_account` (node) | Dedicated node service account (least-privilege, replaces default compute SA) |
| `google_service_account` (ext-dns / cert-mgr) | GSAs for external-dns and cert-manager Workload Identity |
| `google_dns_managed_zone` | Cloud DNS zone for the ingress domain (delegate subdomain from Cloudflare) |
| `local_file` (educates-config.yaml) | Rendered Educates platform config written to the module directory |
| `local_file` (kubeconfig-*.yaml) | Ready-to-use kubeconfig written to the module directory after apply |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated to the target project (`gcloud auth application-default login`)
- [Educates CLI](https://docs.educates.dev/en/stable/installation-guides/cli-based-installation.html) installed locally
- The following GCP APIs enabled on your project:
  - `container.googleapis.com`
  - `compute.googleapis.com`

Enable them in one command:
```bash
gcloud services enable container.googleapis.com compute.googleapis.com \
  --project YOUR_PROJECT_ID
```

---

## Quick Start

```bash
cd terraform/gke-educates
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set project_id, ingress_domain, and cloud_dns_zone at minimum
terraform init
terraform plan
terraform apply
```

After `apply` completes:

```bash
# 1. Use the generated kubeconfig (or run the gcloud command)
export KUBECONFIG=$(terraform output -raw kubeconfig_file)

# 2. Delegate the ingress subdomain in Cloudflare using these NS records
terraform output dns_name_servers

# 3. Deploy the Educates platform onto the cluster
$(terraform output -raw educates_deploy_command)
# equivalent to: educates deploy-platform --config ./educates-config.yaml
```

The `educates deploy-platform` step installs Contour (with the reserved IP), cert-manager, Kyverno, and the Educates operator. It typically takes 5–10 minutes on a fresh cluster.

---

## Variables

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID | `string` | — | ✅ |
| `ingress_domain` | Wildcard DNS domain for workshop ingress | `string` | — | ✅ |
| `cloud_dns_zone` | Cloud DNS managed zone name covering the ingress domain | `string` | — | ✅ |
| `region` | GCP region | `string` | `us-east1` | |
| `zone` | GCP zone (cluster location) | `string` | `us-east1-b` | |
| `cluster_name` | GKE cluster name | `string` | `educates-workshop` | |
| `network_name` | VPC network name | `string` | `educates-network` | |
| `subnet_name` | Subnet name | `string` | `educates-subnet` | |
| `subnet_cidr` | Primary subnet CIDR | `string` | `10.0.0.0/20` | |
| `pods_cidr` | Pod secondary range CIDR | `string` | `10.1.0.0/16` | |
| `services_cidr` | Service secondary range CIDR | `string` | `10.2.0.0/20` | |
| `machine_type` | Worker node machine type | `string` | `n2-standard-4` | |
| `node_count` | Number of worker nodes | `number` | `1` | |
| `node_disk_size_gb` | Worker node boot disk size (GB) | `number` | `100` | |
| `node_disk_type` | Worker node disk type | `string` | `pd-balanced` | |
| `kubernetes_version` | Kubernetes minor version prefix (`1.30`–`1.33`) | `string` | `1.33` | |
| `enable_workload_identity` | Enable Workload Identity | `bool` | `true` | |
| `labels` | Labels applied to all GCP resources | `map(string)` | see variables.tf | |

> **Node sizing:** Educates requires a minimum of **4 vCPU / 16 GB RAM** per node. `n2-standard-4` is the recommended default. Scale `node_count` up for larger cohorts.

---

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | GKE cluster name |
| `cluster_location` | Zone of the cluster |
| `cluster_endpoint` | API server endpoint (sensitive) |
| `ingress_ip` | Static IP — point `*.<ingress_domain>` DNS A record here |
| `dns_name_servers` | Google Cloud DNS NS records — add these to Cloudflare for subdomain delegation |
| `kubeconfig_file` | Path to the generated `kubeconfig-<cluster>.yaml` file |
| `kubeconfig_command` | `gcloud` command to configure `kubectl` (alternative to kubeconfig file) |
| `educates_deploy_command` | `educates deploy-platform` command with generated config path |
| `node_service_account` | Email of the dedicated GKE node service account |
| `external_dns_service_account` | Email of the GSA bound to external-dns via Workload Identity |
| `cert_manager_service_account` | Email of the GSA bound to cert-manager via Workload Identity |
| `network_name` | VPC network name |
| `subnet_name` | Subnet name |

---

## Generated: educates-config.yaml

After `terraform apply` a file named `educates-config.yaml` is written to the module directory. It is pre-filled with the static ingress IP and ingress domain and looks like:

```yaml
clusterInfrastructure:
  provider: "gke"
  gcp:
    project: "my-project"
    cloudDNS:
      zone: "educates.example.com"
    workloadIdentity:
      external-dns: "educates-workshop-ext-dns@my-project.iam.gserviceaccount.com"
      cert-manager: "educates-workshop-cert-mgr@my-project.iam.gserviceaccount.com"

clusterIngress:
  domain: "educates.example.com"

clusterPackages:
  contour:
    enabled: true
    settings:
      infrastructure:
        loadBalancerIP: "34.X.X.X"
  cert-manager:
    enabled: true
  kyverno:
    enabled: true
  educates:
    enabled: true
```

This file is consumed by `educates deploy-platform --config educates-config.yaml` and should not be edited manually — re-running `terraform apply` regenerates it.

---

## DNS Setup

Educates uses wildcard DNS so every workshop session gets its own subdomain. This module creates a **Cloud DNS managed zone** for your ingress domain and expects your root domain to remain in Cloudflare. You delegate only the workshop subdomain to Google Cloud DNS — no Cloudflare configuration is lost.

### Step 1 — Delegate the subdomain from Cloudflare to Google Cloud DNS

After `terraform apply`, get the four Google nameservers assigned to the zone:

```bash
terraform output dns_name_servers
```

In Cloudflare → your root domain → **DNS** → **Add record**, add four **NS records** for the subdomain:

| Type | Name | Value |
|---|---|---|
| NS | `workshops` | `ns-cloud-a1.googledomains.com.` |
| NS | `workshops` | `ns-cloud-a2.googledomains.com.` |
| NS | `workshops` | `ns-cloud-a3.googledomains.com.` |
| NS | `workshops` | `ns-cloud-a4.googledomains.com.` |

> Use the actual values from `terraform output dns_name_servers` — the names above are illustrative. Set TTL to 300 for faster propagation during initial setup.

After this step, Google Cloud DNS is authoritative for `*.workshops.example.com`. Cloudflare remains authoritative for everything else on your domain.

### Step 2 — Point the wildcard A record at the ingress IP

Once DNS has propagated, external-dns (installed by Educates) manages A records automatically. The static IP is reserved so Contour always gets the same address:

```bash
terraform output ingress_ip
```

---

## Teardown

> **Before destroying:** Cloudflare NS records pointing at the Google Cloud DNS zone must be removed manually first, otherwise you'll have dangling delegation records on Cloudflare.



```bash
terraform destroy
```

`deletion_protection` is set to `false` on the cluster, so `terraform destroy` removes all resources including the VPC and static IP without manual intervention.

---

## Relationship to Other Modules

```
terraform/gke-educates/              ← this module
  └── provisions: GKE cluster + Educates platform
      used for: running Educates lab instructions

terraform/kong-serverless-gateways/  ← separate module
  └── provisions: per-student Konnect environments
      used for: Kong Gateway, auth servers, vaults
```

Both modules are independent. The GKE cluster runs the Educates instructional platform; the Konnect environments are the systems students configure during the workshops.
