provider "google" {
  project               = var.bootstrap_project_id
  billing_project       = var.bootstrap_project_id
  user_project_override = true
}
