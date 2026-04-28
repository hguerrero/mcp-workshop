locals {
  student_ids = [for i in range(var.student_start_number, var.student_count + var.student_start_number) : format("%02d", i)]
}

resource "konnect_gateway_control_plane" "serverless_cp" {
  for_each = toset(local.student_ids)

  name         = "${var.student_name_prefix}${each.key}-cp"
  cluster_type = "CLUSTER_TYPE_SERVERLESS_V1"
  description  = "${var.control_plane_description} ${var.student_name_prefix}${each.key}"
  labels       = var.control_plane_labels
  auth_type    = "pinned_client_certs"
  cloud_gateway = true
}

resource "konnect_cloud_gateway_configuration" "serverless_gw" {
  for_each = toset(local.student_ids)

  control_plane_geo = "us"
  control_plane_id  = konnect_gateway_control_plane.serverless_cp[each.key].id
  dataplane_groups = [
    {
      provider = "aws"
      region   = "us"
    }
  ]
  kind = "serverless.v1"
}
