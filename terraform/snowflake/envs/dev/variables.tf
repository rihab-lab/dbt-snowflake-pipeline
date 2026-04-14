
variable "snowflake_username" { type = string }

variable "snowflake_password" {
  type      = string
  sensitive = true
}

variable "svc_dbt_password" {
  type      = string
  sensitive = true
}

variable "snowflake_organization_name" {
  type = string
}

variable "snowflake_account_name" {
  type = string
}
