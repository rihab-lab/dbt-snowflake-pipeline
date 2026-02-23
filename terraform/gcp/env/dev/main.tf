module "project" {
  source             = "../../modules/org_projects"
  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  project_prefix = "snowdbt"
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

  depends_on = [module.project]
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

  depends_on = [module.project]
}

resource "google_storage_bucket_iam_member" "landing_admin" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectAdmin"
  member = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_storage_bucket.landing]
}

#to be addded storage.bucketViewer
resource "google_storage_bucket_iam_member" "archive_admin" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_storage_bucket.landing]
}
#composer
# ----------------------------------------
# APIs requises
# ----------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "composer.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project            = local.project_id
  service            = each.value
  disable_on_destroy = false
}

# ----------------------------------------
# Cloud Composer 2 Service Agent permissions
# (obligatoire pour créer l'env)
# ----------------------------------------
resource "google_project_iam_member" "composer_service_agent_v2ext" {
  project = local.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${module.project.project_numbers["dev"]}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# Attendre la propagation IAM (évite le 400 failedPrecondition)
resource "time_sleep" "wait_composer_iam" {
  depends_on      = [google_project_iam_member.composer_service_agent_v2ext]
  create_duration = "60s"
}

# ----------------------------------------
# Service Account Composer (workers)
# ----------------------------------------
resource "google_service_account" "composer" {
  project      = local.project_id
  account_id   = "sa-composer-dev"
  display_name = "Composer SA (dev)"

  depends_on = [google_project_service.apis]
}

# ----------------------------------------
# IAM sur tes buckets (landing/archive)
# ----------------------------------------
resource "google_storage_bucket_iam_member" "landing_viewer_composer" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_storage_bucket_iam_member" "archive_admin_composer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.composer.email}"
}

# Secrets (si tu stockes les creds dbt/snowflake dans Secret Manager)
resource "google_project_iam_member" "composer_secret_accessor" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

# ----------------------------------------
# Composer environment DEV
# ----------------------------------------
resource "google_composer_environment" "dev" {
  project = local.project_id
  name    = "composer-pipeone-dev"
  region  = var.region

  depends_on = [
    time_sleep.wait_composer_iam
  ]

  config {
    node_config {
      service_account = google_service_account.composer.email
    }

    software_config {
      image_version = "composer-2-airflow-2"
    }

    workloads_config {
      scheduler {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 10
        count      = 1
      }

      web_server {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 10
      }

      worker {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 10
        min_count  = 1
        max_count  = 2
      }
    }
  }
}