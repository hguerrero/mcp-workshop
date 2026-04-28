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

# Identity Auth Server per student
resource "konnect_identity_auth_server" "student_auth_server" {
  for_each = toset(local.student_ids)

  name        = "${var.student_name_prefix}${each.key}-auth-server"
  description = "Identity auth server for ${var.student_name_prefix}${each.key}"
  audience    = "https://${var.student_name_prefix}${each.key}.example.com"
}

# Identity Auth Server Client (Application) per student
resource "konnect_identity_auth_server_client" "student_application" {
  for_each = toset(local.student_ids)

  name           = "${var.student_name_prefix}${each.key}-application"
  auth_server_id = konnect_identity_auth_server.student_auth_server[each.key].id
  grant_types    = ["client_credentials"]
  response_types = ["token"]
  client_secret  = "supersecret"
  id             = "${var.student_name_prefix}${each.key}"
}
