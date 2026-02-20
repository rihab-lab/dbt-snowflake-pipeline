############################
# DBT ROLE - PRIVILEGES
############################

# 1) Warehouse USAGE + OPERATE
resource "snowflake_grant_privileges_to_account_role" "dbt_wh_usage_operate" {
  account_role_name = snowflake_account_role.role_dbt.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.wh_dbt.name
  }
}

# 2) Database USAGE
resource "snowflake_grant_privileges_to_account_role" "dbt_db_usage" {
  account_role_name = snowflake_account_role.role_dbt.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

# 3) Schemas: USAGE + CREATE TABLE + CREATE VIEW (+ optionnel CREATE FUNCTION)
resource "snowflake_grant_privileges_to_account_role" "dbt_schema_privs" {
  for_each          = snowflake_schema.schemas
  account_role_name = snowflake_account_role.role_dbt.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE FUNCTION"]

  on_schema {
    schema_name = each.value.fully_qualified_name
  }
}

############################
# READONLY ROLE - PRIVILEGES
############################

# Database USAGE for readonly role
resource "snowflake_grant_privileges_to_account_role" "ro_db_usage" {
  count             = var.create_readonly_role ? 1 : 0
  account_role_name = snowflake_account_role.role_readonly[0].name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

# Schema USAGE for readonly schemas (SILVER/GOLD)
resource "snowflake_grant_privileges_to_account_role" "ro_schema_usage" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  account_role_name = snowflake_account_role.role_readonly[0].name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.schemas[each.value].fully_qualified_name
  }
}

# SELECT on FUTURE TABLES in readonly schemas
resource "snowflake_grant_privileges_to_account_role" "ro_future_tables_select" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  account_role_name = snowflake_account_role.role_readonly[0].name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.schemas[each.value].fully_qualified_name
    }
  }
}

# SELECT on FUTURE VIEWS in readonly schemas
resource "snowflake_grant_privileges_to_account_role" "ro_future_views_select" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  account_role_name = snowflake_account_role.role_readonly[0].name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = snowflake_schema.schemas[each.value].fully_qualified_name
    }
  }
}
