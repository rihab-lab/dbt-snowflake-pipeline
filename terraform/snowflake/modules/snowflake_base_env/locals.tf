locals {
  env_upper = upper(var.env)

  db_name     = "${var.db_name_prefix}_${local.env_upper}"
  wh_dbt_name = "WH_DBT_${local.env_upper}"

  role_dbt_name = "ROLE_DBT_${local.env_upper}"
  role_ro_name  = "ROLE_READONLY_${local.env_upper}"

  user_dbt_name = "SVC_DBT_${local.env_upper}"
}
