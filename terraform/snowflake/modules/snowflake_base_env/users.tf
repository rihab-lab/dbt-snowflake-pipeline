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


# Grant ROLE_DBT_<ENV> to the user
resource "snowflake_grant_account_role" "grant_dbt_role_to_user" {
  role_name = snowflake_account_role.role_dbt.name
  user_name = snowflake_user.svc_dbt.name
}