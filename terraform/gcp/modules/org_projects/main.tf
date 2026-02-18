locals {
  envs = toset(var.environments)
}

resource "google_project" "projects" {
  for_each            = local.envs

  project_id          = "${var.project_prefix}-${each.value}"
  name                = "${var.project_prefix}-${each.value}"
  org_id              = var.org_id
  billing_account     = var.billing_account_id

  labels = merge(
    var.labels,
    {
      environment = each.value
      managed_by  = "terraform"
    }
  )
}
