resource "snowflake_account_role" "role_dbt" {
  name = local.role_dbt_name
}

resource "snowflake_account_role" "role_readonly" {
  count = var.create_readonly_role ? 1 : 0
  name  = local.role_ro_name
}
