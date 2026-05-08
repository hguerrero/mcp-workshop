variable "workshop_system_account_name" {
  description = "Name for the workshop system account"
  type        = string
  default     = "Data Path Workshop System Account"
}

variable "workshop_system_account_description" {
  description = "Description for the workshop system account"
  type        = string
  default     = "System account for Kong Data Path Workshop automation"
}

variable "student_count" {
  description = "Number of students to provision serverless gateways for"
  type        = number
  default     = 5
}

variable "student_start_number" {
  description = "Starting number for student IDs (e.g., 1 creates student01)"
  type        = number
  default     = 1
}

variable "student_name_prefix" {
  description = "Prefix for student names"
  type        = string
  default     = "student"
}

variable "control_plane_labels" {
  description = "Labels to apply to the control planes"
  type        = map(string)
  default     = {
    purpose      = "workshop"
    managed_by   = "terraform"
  }
}

variable "control_plane_description" {
  description = "Description for the control planes"
  type        = string
  default     = "Serverless gateway for workshop student"
}

# ── SSO/OIDC Configuration ────────────────────────────────────────────────────

variable "enable_sso_config" {
  description = "Whether to create and configure SSO/OIDC identity provider. Set to false if you already have an identity provider configured."
  type        = bool
  default     = true
}

variable "workshop_sso_oidc_org_login_path" {
  description = "OIDC login path for the organization SSO (mandatory when enable_sso_config is true)"
  type        = string
  default     = ""
}

variable "workshop_sso_oidc_issuer" {
  description = "OIDC issuer URL for SSO configuration"
  type        = string
  default     = "https://workshop-idp.com"
}

variable "workshop_sso_oidc_client_id" {
  description = "OIDC client ID for SSO configuration"
  type        = string
  default     = "workshop-client-12345"
}

variable "workshop_sso_oidc_client_secret" {
  description = "OIDC client secret for SSO configuration"
  type        = string
  sensitive   = true
  default     = "L2bQ8nZ5yX1wJ"
}
