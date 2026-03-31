module "project" {
  source             = "../../modules/org_projects"
  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  project_prefix = "snowdbt1"
  environments   = ["dev"]

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# On récupère l'ID du projet créé
locals {
  project_id = module.project.projects_map["dev"]
}

resource "google_project_iam_member" "ci_storage_admin" {
  project = local.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.ci_service_account_email}"

  depends_on = [module.project]
}
# Bucket landing
resource "google_storage_bucket" "landing" {
  name                        = "bck-pipeone-landing-dev"
  project                     = local.project_id
  location                    = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
  }

  depends_on = [module.project,
  google_project_iam_member.ci_storage_admin]
  
}

# Bucket archive
resource "google_storage_bucket" "archive" {
  name                        = "bck-pipeone-archive-dev"
  project                     = local.project_id
  location                    = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition { age = 180 }
    action    { type = "Delete" }
  }

  depends_on = [module.project,
  google_project_iam_member.ci_storage_admin]
}

resource "google_storage_bucket_iam_member" "landing_bucket_viewer" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.bucketViewer"
  member = "user:rihab.bahri7@rbaapp.com"
}

resource "google_storage_bucket_iam_member" "landing_object_viewer" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectViewer"
  member = "user:rihab.bahri7@rbaapp.com"
}

resource "google_storage_bucket_iam_member" "archive_bucket_viewer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.bucketViewer"
  member = "user:rihab.bahri7@rbaapp.com"
}

resource "google_storage_bucket_iam_member" "archive_object_viewer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectViewer"
  member = "user:rihab.bahri7@rbaapp.com"
}