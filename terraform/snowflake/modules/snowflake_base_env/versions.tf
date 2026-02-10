#verrouiller les versions
terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.1"
    }
  }
}

