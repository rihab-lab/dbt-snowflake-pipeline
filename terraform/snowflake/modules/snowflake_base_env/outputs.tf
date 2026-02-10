output "database_name" {
  value = snowflake_database.db.name
}

output "warehouse_dbt_name" {
  value = snowflake_warehouse.wh_dbt.name
}

output "role_dbt_name" {
  value = snowflake_role.role_dbt.name
}

output "role_readonly_name" {
  value = var.create_readonly_role ? snowflake_role.role_readonly[0].name : null
}

output "svc_dbt_user_name" {
  value = snowflake_user.svc_dbt.name
}
