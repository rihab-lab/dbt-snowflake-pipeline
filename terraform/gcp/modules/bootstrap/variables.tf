variable "bootstrap_project_id" {
  type = string
}

variable "org_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "allowed_ref" {
  type    = string
  default = "refs/heads/main"
}

variable "ci_service_account_id" {
  type    = string
  default = "sa-github-terraform"
}



variable "region" {
  type        = string
  description = "GCS region for resources"
  default = "europe-west1"
}

