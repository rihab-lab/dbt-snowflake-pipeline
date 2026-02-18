resource "google_storage_bucket" "tfstate" {
  name     = "tfstate-bootstrap-project-487710"
  project  = var.bootstrap_project_id
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "tfstate_object_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_storage_bucket_iam_member" "tfstate_bucket_reader" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.ci.email}"
}
