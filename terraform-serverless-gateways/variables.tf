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

variable "system_account_id" {
  description = "System account ID for creating access token"
  type        = string
}
