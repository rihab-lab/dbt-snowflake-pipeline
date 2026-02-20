#Rendre le module réutilisable pour DEV/STG/PROD.
variable "env" {
  description = "Environment name (DEV/STG/PROD)"
  type        = string
}

variable "db_name_prefix" {
  description = "Database prefix, e.g. MYDATA -> MYDATA_DEV"
  type        = string
}

variable "schemas" {
  description = "Schemas to create."
  type        = list(string)
  default     = ["RAW", "BRONZE", "SILVER", "GOLD"]
}
#C’est la liste des schemas que le rôle readonly a le droit de lire
variable "readonly_schemas" {
  description = "Schemas readable by readonly role."
  type        = list(string)
  default     = ["SILVER", "GOLD"]
}

variable "warehouse_size" {
  description = "Size of dbt warehouse."
  type        = string
  default     = "SMALL"
}

variable "warehouse_auto_suspend_seconds" {
  description = "Auto suspend seconds for warehouse."
  type        = number
  default     = 60
}
#pour créer un rôle lecture seule / TRUE quand tu as des consommateurs : BI
variable "create_readonly_role" {
  description = "Create ROLE_READONLY_<ENV>."
  type        = bool
  default     = true
}

#dbt (via Airflow) se connecte à Snowflake avec ce user
variable "svc_dbt_password" {
  description = "Password for SVC_DBT_<ENV> (MVP). Prefer key-pair later."
  type        = string
  sensitive   = true
}
