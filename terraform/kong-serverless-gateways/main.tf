locals {
  student_ids = [for i in range(var.student_start_number, var.student_count + var.student_start_number) : format("%02d", i)]
}

# ── Workshop System Account ───────────────────────────────────────────────────

resource "konnect_system_account" "workshop_system_account" {
  name         = var.workshop_system_account_name
  description  = var.workshop_system_account_description
  konnect_managed = false
}

# Assign system account to control plane admin team
resource "konnect_system_account_team" "workshop_system_account_team" {
  account_id = konnect_system_account.workshop_system_account.id
  team_id    = data.konnect_team.control_plane_admin.id
}

# ── Per-student Serverless Control Planes ────────────────────────────────────

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
  redirect_uris  = ["https://httpbin.konghq.com", "https://app.insomnia.rest/oauth/redirect"]
  client_secret  = "supersecret"
  id             = "${var.student_name_prefix}${each.key}"
}

# ── System account token (shared — used for decK syncs in lab instructions) ──

resource "konnect_system_account_access_token" "token" {
  account_id = konnect_system_account.workshop_system_account.id
  expires_at = timeadd(timestamp(), "8760h") # 1 year — refresh before next cohort
  name       = "${var.student_name_prefix}-workshop-token"
}

# Config Store per student
resource "konnect_gateway_config_store" "student_config_store" {
  for_each = toset(local.student_ids)

  control_plane_id = konnect_gateway_control_plane.serverless_cp[each.key].id
  name             = "${var.student_name_prefix}${each.key}-config-store"
}

# Vault per student using Konnect Config Store
resource "konnect_gateway_vault" "student_vault" {
  for_each = toset(local.student_ids)

  control_plane_id = konnect_gateway_control_plane.serverless_cp[each.key].id
  name             = "konnect"
  prefix           = "ai"
  description      = "Konnect config store vault for ${var.student_name_prefix}${each.key}"
  config = jsonencode({
    config_store_id = konnect_gateway_config_store.student_config_store[each.key].id
  })
}

# ── Organization SSO Configuration ────────────────────────────────────────────

# Create the OIDC identity provider (only if not already exists)
resource "konnect_identity_provider" "org_sso_config" {
  count = var.enable_sso_config ? 1 : 0

  type       = "oidc"
  login_path = var.workshop_sso_oidc_org_login_path
  enabled    = true

  config = {
    oidc_identity_provider_config = {
      issuer_url    = var.workshop_sso_oidc_issuer
      client_id     = var.workshop_sso_oidc_client_id
      client_secret = var.workshop_sso_oidc_client_secret

      scopes = [
        "openid",
        "email",
        "profile"
      ]

      claim_mappings = {
        email  = "email"
        name   = "name"
        groups = "groups"
      }
    }
  }
}

# Enable Organization SSO (only if creating identity provider)
resource "konnect_authentication_settings" "enable_org_sso_config" {
  count = var.enable_sso_config ? 1 : 0

  basic_auth_enabled      = true
  oidc_auth_enabled       = true
  saml_auth_enabled       = false
  idp_mapping_enabled     = true
  konnect_mapping_enabled = true

  depends_on = [konnect_identity_provider.org_sso_config]
}

# ── Collect default Konnect Teams for SSO Team Mappings ──────────────────────

data "konnect_team" "organization_admin" {
  filter = { name = { eq = "organization-admin" } }
}

data "konnect_team" "control_plane_admin" {
  filter = { name = { eq = "control-plane-admin" } }
}

data "konnect_team" "organization_admin_readonly" {
  filter = { name = { eq = "organization-admin-readonly" } }
}

data "konnect_team" "analytics_admin" {
  filter = { name = { eq = "analytics-admin" } }
}

data "konnect_team" "portal_admin" {
  filter = { name = { eq = "portal-admin" } }
}

# Create the Team Mappings (only if creating identity provider)
resource "null_resource" "org_sso_team_mappings" {
  count = var.enable_sso_config ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      curl --request PATCH \
          --url "${var.konnect_api_url}/v3/identity-provider/team-group-mappings" \
          --header "Authorization: Bearer ${var.konnect_personal_access_token}" \
          --header 'Content-Type: application/json' \
          --data '{
          "data": [
            {
              "team_id": "${data.konnect_team.organization_admin.id}",
              "groups": [
                "Custom User",
                "Custom Admin",
                "Custom Viewer"
              ]
            },
            {
              "team_id": "${data.konnect_team.control_plane_admin.id}",
              "groups": [
                "Control Plane Admin"
              ]
            },
            {
              "team_id": "${data.konnect_team.organization_admin_readonly.id}",
              "groups": [
                "Organization Admin RO"
              ]
            },
            {
              "team_id": "${data.konnect_team.analytics_admin.id}",
              "groups": [
                "Analytics Admin"
              ]
            },
            {
              "team_id": "${data.konnect_team.portal_admin.id}",
              "groups": [
                "Portal Admin",
                "API Product Developer",
                "API Product Admin"
              ]
            }
          ]
        }'
EOT
  }

  depends_on = [
    konnect_identity_provider.org_sso_config,
    konnect_authentication_settings.enable_org_sso_config
  ]
}


resource "konnect_gateway_config_store_secret" "konnect_mcp_spat" {
  for_each = toset(local.student_ids)

  control_plane_id = konnect_gateway_control_plane.serverless_cp[each.key].id
  config_store_id  = konnect_gateway_config_store.student_config_store[each.key].id
  key              = "konnect-mcp-spat"
  value            = "Authorization: Bearer ${konnect_system_account_access_token.token.token}"
}

# Global CORS plugin for each student control plane
resource "konnect_gateway_plugin_cors" "global_cors" {
  for_each = toset(local.student_ids)

  control_plane_id = konnect_gateway_control_plane.serverless_cp[each.key].id

  instance_name = "global-cors"
  
  config = {
    allow_origin_absent = true
    origins = ["*"]
    methods = ["GET", "HEAD", "PUT", "PATCH", "POST", "DELETE", "OPTIONS", "TRACE", "CONNECT"]
    credentials = true
    max_age = 3600
    preflight_continue = false
  }
}
