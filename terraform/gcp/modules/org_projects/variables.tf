variable "org_id" { type = string }

variable "billing_account_id" {
  type = string
  description = "Billing account id like XXXXXX-XXXXXX-XXXXXX"
}

variable "project_prefix" {
  type        = string
  description = "Prefix for project IDs"
  default     = "snowdbt"
}

variable "environments" {
  type        = list(string)
  description = "Environments to create"
  default     = ["dev", "stg", "prod"]
}

variable "labels" {
  type        = map(string)
  description = "Common labels applied to all projects"
  default     = {}
}
