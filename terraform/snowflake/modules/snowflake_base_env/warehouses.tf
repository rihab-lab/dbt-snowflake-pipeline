resource "snowflake_warehouse" "wh_dbt" {
  name                = local.wh_dbt_name
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.warehouse_auto_suspend_seconds
  auto_resume         = true
  initially_suspended = true
}
