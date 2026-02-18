module "org_projects" {
  source = "../modules/org_projects"

  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  project_prefix = var.project_prefix
  environments   = var.environments
  labels         = var.labels
}
