locals {
  projects = {
    for env in var.environments :
    env => "${var.project_prefix}-${env}"
  }
}

resource "google_project" "project" {
  for_each = local.projects

  project_id      = each.value
  name            = each.value
  org_id          = var.org_id
  billing_account = var.billing_account_id

  labels = merge(
    var.labels,
    {
      environment = each.key
      managed_by  = "terraform"
    }
  )
}
