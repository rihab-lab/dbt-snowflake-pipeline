resource "snowflake_user" "svc_dbt" {
  name         = local.user_dbt_name
  login_name   = local.user_dbt_name
  display_name = local.user_dbt_name
  disabled     = false

  default_role      = snowflake_role.role_dbt.name
  default_warehouse = snowflake_warehouse.wh_dbt.name

  # MVP: password auth
  password = var.svc_dbt_password
}

resource "snowflake_role_grants" "grant_role_dbt_to_user" {
  role_name = snowflake_role.role_dbt.name
  users     = [snowflake_user.svc_dbt.name]
}
