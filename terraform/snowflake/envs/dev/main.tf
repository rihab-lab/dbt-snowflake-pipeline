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
#create snowflake stage
resource "snowflake_storage_integration" "gcs_int" {
  name    = "GCS_STORAGE_INT"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider = "GCS"

  storage_allowed_locations = [
    "gcs://bck-pipeone-landing-dev/"
  ]
}
resource "snowflake_file_format" "csv_format" {
  name     = "CSV_FORMAT"
  database = "MYDATA_DEV"
  schema   = "RAW"

  format_type = "CSV"

  skip_header = 1
  field_optionally_enclosed_by = "\""
  null_if = ["NULL", "null", ""]
}
resource "snowflake_stage" "gcp_stage" {
  name     = "EXTERNAL_GCP_STAGE_STORAGE"
  database = "MYDATA_DEV"
  schema   = "RAW"

  url = "gcs://bck-pipeone-landing-dev/"

  storage_integration = snowflake_storage_integration.gcs_int.name

  file_format = "FORMAT_NAME = MYDATA_DEV.RAW.CSV_FORMAT"

  depends_on = [
    snowflake_storage_integration.gcs_int,
    snowflake_file_format.csv_format
  ]
}