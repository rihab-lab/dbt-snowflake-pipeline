resource "google_storage_bucket" "tfstate" {
  name     = "tfstate-bootstrap-project-487710"
  project  = var.bootstrap_project_id
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
