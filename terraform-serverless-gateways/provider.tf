variable "konnect_personal_access_token" {
  description = "Personal access token for Konnect"
  type        = string
  sensitive   = true
}

variable "konnect_api_url" {
  description = "The Kong Konnect API URL to use."
  type        = string
  default     = "https://us.api.konghq.com"
}

variable "konnect_region" {
  description = "The Kong Konnect region to be used"
  type        = string
  default     = "us"
}

terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = var.konnect_personal_access_token
  server_url            = var.konnect_api_url
}
