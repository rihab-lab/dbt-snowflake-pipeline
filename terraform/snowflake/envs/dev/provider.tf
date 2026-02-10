terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.1"
    }
  }
}

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name

  user     = var.snowflake_username
  password = var.snowflake_password
  role     = "ACCOUNTADMIN"
}
