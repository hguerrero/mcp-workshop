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