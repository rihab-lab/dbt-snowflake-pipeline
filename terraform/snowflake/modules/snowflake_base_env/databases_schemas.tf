resource "snowflake_database" "db" {
  name = local.db_name
}

resource "snowflake_schema" "schemas" {
  for_each = toset(var.schemas)

  database = snowflake_database.db.name
  name     = each.value
}
