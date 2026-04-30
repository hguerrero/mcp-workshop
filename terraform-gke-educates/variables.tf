variable "project_id" {
  description = "GCP project ID where all resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster and supporting resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the GKE control plane (used for zonal clusters)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "educates-workshop"
}

variable "network_name" {
  description = "Name of the VPC network to create"
  type        = string
  default     = "educates-network"
}

variable "subnet_name" {
  description = "Name of the subnet to create inside the VPC"
  type        = string
  default     = "educates-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR range for pod IPs (alias IP range)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR range for service ClusterIPs (alias IP range)"
  type        = string
  default     = "10.2.0.0/20"
}

variable "machine_type" {
  description = "Machine type for GKE worker nodes. Must be at least 4 vCPU / 16 GB RAM (e2-standard-4 or n2-standard-4)"
  type        = string
  default     = "n2-standard-4"
}

variable "node_count" {
  description = "Number of worker nodes in the node pool. Educates requires a minimum of 3."
  type        = number
  default     = 3
}

variable "node_disk_size_gb" {
  description = "Boot disk size in GB for each worker node"
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Boot disk type for worker nodes (pd-standard, pd-balanced, or pd-ssd)"
  type        = string
  default     = "pd-balanced"
}

variable "kubernetes_version" {
  description = "Minimum GKE master version. Leave empty to use the default channel version."
  type        = string
  default     = ""
}

variable "ingress_domain" {
  description = "Wildcard DNS domain used for workshop ingress (e.g. workshops.example.com). A DNS A record *.workshops.example.com must point at the static IP output by this module."
  type        = string
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity on the cluster. Required by Educates for GKE."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to all GCP resources created by this module"
  type        = map(string)
  default = {
    managed_by = "terraform"
    purpose    = "educates-workshop"
  }
}
