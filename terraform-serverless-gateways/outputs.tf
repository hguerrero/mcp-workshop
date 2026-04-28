output "serverless_gateway_urls" {
  description = "Map of student IDs to their serverless gateway URLs"
  value = {
    for student_id in local.student_ids :
    student_id => "${split(".", konnect_gateway_control_plane.serverless_cp[student_id].config.control_plane_endpoint)[0]}.us.serverless.gateways.konggateway.com"
  }
}

output "control_plane_ids" {
  description = "Map of student IDs to their control plane IDs"
  value = {
    for student_id in local.student_ids : student_id => konnect_gateway_control_plane.serverless_cp[student_id].id
  }
}

output "control_plane_names" {
  description = "Map of student IDs to their control plane names"
  value = {
    for student_id in local.student_ids : student_id => konnect_gateway_control_plane.serverless_cp[student_id].name
  }
}

output "auth_server_ids" {
  description = "Map of student IDs to their identity auth server IDs"
  value = {
    for student_id in local.student_ids : student_id => konnect_identity_auth_server.student_auth_server[student_id].id
  }
}

output "application_client_ids" {
  description = "Map of student IDs to their identity auth server client IDs"
  value = {
    for student_id in local.student_ids : student_id => konnect_identity_auth_server_client.student_application[student_id].id
  }
}

output "application_client_secrets" {
  description = "Map of student IDs to their identity auth server client secrets (sensitive)"
  sensitive   = true
  value = {
    for student_id in local.student_ids : student_id => konnect_identity_auth_server_client.student_application[student_id].client_secret
  }
}