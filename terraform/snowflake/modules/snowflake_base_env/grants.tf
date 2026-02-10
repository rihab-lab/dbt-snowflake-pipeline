############################
# DBT ROLE GRANTS
############################
#dbt : USAGE DB + schemas, CREATE TABLE/VIEW sur schemas, USAGE/OPERATE warehouse
#readonly : USAGE DB + schemas (SILVER/GOLD), SELECT sur futurs objets

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

resource "snowflake_database_grant" "dbt_db_usage" {
  database_name = snowflake_database.db.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_dbt.name]
}

resource "snowflake_schema_grant" "dbt_schema_usage" {
  for_each      = snowflake_schema.schemas
  database_name = each.value.database
  schema_name   = each.value.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_dbt.name]
}

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

############################
# READONLY ROLE GRANTS
############################

resource "snowflake_database_grant" "ro_db_usage" {
  count         = var.create_readonly_role ? 1 : 0
  database_name = snowflake_database.db.name
  privilege     = "USAGE"
  roles         = [snowflake_role.role_readonly[0].name]
}

resource "snowflake_schema_grant" "ro_schema_usage" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  database_name = snowflake_database.db.name
  schema_name   = each.value
  privilege     = "USAGE"
  roles         = [snowflake_role.role_readonly[0].name]
}

resource "snowflake_schema_grant" "ro_select_future" {
  for_each = var.create_readonly_role ? toset(var.readonly_schemas) : toset([])

  database_name = snowflake_database.db.name
  schema_name   = each.value
  privilege     = "SELECT"
  roles         = [snowflake_role.role_readonly[0].name]
  on_future     = true
}
