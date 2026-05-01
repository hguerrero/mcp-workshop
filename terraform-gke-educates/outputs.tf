output "cluster_name" {
  description = "Name of the provisioned GKE cluster"
  value       = google_container_cluster.educates.name
}

output "cluster_location" {
  description = "Zone where the GKE cluster is deployed"
  value       = google_container_cluster.educates.location
}

output "cluster_endpoint" {
  description = "GKE cluster API server endpoint"
  value       = google_container_cluster.educates.endpoint
  sensitive   = true
}

output "ingress_ip" {
  description = "Static external IP address reserved for the Contour ingress load balancer. Create a wildcard DNS A record pointing to this IP."
  value       = google_compute_address.ingress.address
}

output "kubeconfig_command" {
  description = "gcloud command to configure kubectl access to the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.educates.name} --zone ${var.zone} --project ${var.project_id}"
}

output "educates_deploy_command" {
  description = "educates CLI command to install the Educates platform onto the cluster (run after kubeconfig_command)"
  value       = "educates deploy-platform --config ${abspath(local_file.educates_config.filename)}"
}

output "dns_name_servers" {
  description = "Google Cloud DNS name servers for the managed zone. Add these as NS records for your ingress subdomain in Cloudflare to delegate it to Google Cloud DNS."
  value       = google_dns_managed_zone.educates.name_servers
}

output "external_dns_service_account" {
  description = "Email of the GSA bound to the external-dns Kubernetes Service Account via Workload Identity"
  value       = google_service_account.external_dns.email
}

output "cert_manager_service_account" {
  description = "Email of the GSA bound to the cert-manager Kubernetes Service Account via Workload Identity"
  value       = google_service_account.cert_manager.email
}

output "network_name" {
  description = "Name of the VPC network created for the cluster"
  value       = google_compute_network.educates.name
}

output "subnet_name" {
  description = "Name of the subnet created for the cluster"
  value       = google_compute_subnetwork.educates.name
}
