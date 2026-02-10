terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.90"
    }
  }
}

provider "snowflake" {
  account  = var.snowflake_account
  user     = var.snowflake_username
  password = var.snowflake_password
  role     = "ACCOUNTADMIN"
}