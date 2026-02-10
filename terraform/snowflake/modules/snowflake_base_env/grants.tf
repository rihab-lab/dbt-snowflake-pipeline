############################
# DBT ROLE GRANTS
############################

# 1) Warehouse privileges for dbt
resource "snowflake_warehouse_grant" "dbt_wh_usage" {
  warehouse_name = snowflake_warehouse.wh_dbt.name
  privilege      = "USAGE"
  roles          = [snowflake_role.role_dbt.name]
}

resource "snowflake_warehouse_grant" "dbt_wh_operate" {
  warehouse_name = snowflake_warehouse.wh_dbt.name
  privilege      = "OPERATE"
  roles          = [snowflake_role.role_dbt.name]
}

# 2) Database usage for dbt
resource "snowflake_database_grant" "dbt_db_usage" {
  database_name = snowflake_database.db.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_dbt.name]
}

# 3) Schema usage for dbt (RAW/BRONZE/SILVER/GOLD)
resource "snowflake_schema_grant" "dbt_schema_usage" {
  for_each      = snowflake_schema.schemas
  database_name = each.value.database
  schema_name   = each.value.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_dbt.name]
}

# 4) Allow dbt to create objects in schemas
resource "snowflake_schema_grant" "dbt_schema_create_table" {
  for_each      = snowflake_schema.schemas
  database_name = each.value.database
  schema_name   = each.value.name
  privilege     = "CREATE TABLE"
  roles         = [snowflake_role.role_dbt.name]
}

resource "snowflake_schema_grant" "dbt_schema_create_view" {
  for_each      = snowflake_schema.schemas
  database_name = each.value.database
  schema_name   = each.value.name
  privilege     = "CREATE VIEW"
  roles         = [snowflake_role.role_dbt.name]
}

# Optional (only if you use UDFs/macros that create functions)
resource "snowflake_schema_grant" "dbt_schema_create_function" {
  for_each      = snowflake_schema.schemas
  database_name = each.value.database
  schema_name   = each.value.name
  privilege     = "CREATE FUNCTION"
  roles         = [snowflake_role.role_dbt.name]
}

############################
# READONLY ROLE GRANTS
############################

# If readonly role is enabled, give it USAGE on the database
resource "snowflake_database_grant" "ro_db_usage" {
  count         = var.create_readonly_role ? 1 : 0
  database_name = snowflake_database.db.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_readonly[0].name]
}

# Give USAGE on readonly schemas (typically SILVER & GOLD)
resource "snowflake_schema_grant" "ro_schema_usage" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  database_name = snowflake_database.db.name
  schema_name   = each.value
  privilege     = "USAGE"
  roles         = [snowflake_role.role_readonly[0].name]
}

# ✅ Correct way: SELECT is on TABLE/VIEW, not on SCHEMA
# SELECT on FUTURE TABLES in readonly schemas
resource "snowflake_table_grant" "ro_select_future_tables" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  database_name = snowflake_database.db.name
  schema_name   = each.value
  privilege     = "SELECT"
  roles         = [snowflake_role.role_readonly[0].name]

  on_future = true
}

# SELECT on FUTURE VIEWS in readonly schemas
resource "snowflake_view_grant" "ro_select_future_views" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  database_name = snowflake_database.db.name
  schema_name   = each.value
  privilege     = "SELECT"
  roles         = [snowflake_role.role_readonly[0].name]

  on_future = true
}
