module "snowflake_env" {
  source = "../../modules/snowflake_base_env"

  env            = "DEV"
  db_name_prefix = "MYDATA"

  schemas          = ["RAW", "BRONZE", "SILVER", "GOLD"]
  readonly_schemas = ["SILVER", "GOLD"]

  warehouse_size                 = "SMALL"
  warehouse_auto_suspend_seconds = 60

  create_readonly_role = true

  svc_dbt_password = var.svc_dbt_password
}
