variable "bootstrap_project_id" {
  type        = string
  description = "Bootstrap project used to run Terraform (quota/billing project)"
}

variable "org_id" {
  type = string
}

variable "billing_account_id" {
  type        = string
  description = "Billing account id like XXXXXX-XXXXXX-XXXXXX"
}

variable "project_prefix" {
  type    = string
  default = "snowdbt"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "stg", "prod"]
}

variable "labels" {
  type    = map(string)
  default = { app = "snowdbt" }
}
