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
variable "snowflake_account" { type = string sensitive = true }
variable "snowflake_user" { type = string sensitive = true }
variable "snowflake_password" { type = string sensitive = true }
variable "snowflake_role" { type = string sensitive = true }
variable "snowflake_warehouse" { type = string sensitive = true }
variable "snowflake_database" { type = string sensitive = true }
variable "snowflake_schema" { type = string sensitive = true }