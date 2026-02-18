locals {
  projects = {
    for env in var.environments :
    env => "${var.project_prefix}-${env}"
  }
}

resource "google_project" "env" {
  for_each   = local.projects

  project_id = each.value
  name       = each.value

  org_id = var.org_id

  labels = merge(
    var.labels,
    { environment = each.key }
  )
}

# Attach billing to each created project
resource "google_project_billing_info" "billing" {
  for_each        = google_project.env
  project         = each.value.project_id
  billing_account = var.billing_account_id
}
