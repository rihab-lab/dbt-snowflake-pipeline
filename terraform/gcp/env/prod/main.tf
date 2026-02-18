module "project" {
  source             = "../../modules/org_projects"
  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  project_id = "snowdbt-dev"

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
