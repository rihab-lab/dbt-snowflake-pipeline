locals {
  required_apis = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudbilling.googleapis.com"
  ]
}

resource "google_project_service" "required" {
  for_each           = toset(local.required_apis)
  project            = var.bootstrap_project_id
  service            = each.value
  disable_on_destroy = false
}
