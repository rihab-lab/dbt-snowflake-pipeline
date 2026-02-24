variable "bootstrap_project_id" { type = string }
variable "org_id" { type = string }
variable "billing_account_id" { type = string }
variable "region" {
  type    = string
  default = "europe-west1"
}
variable "ci_service_account_email" {
  description = "Service Account utilisé par la CI pour déployer les DAGs"
  type        = string
}