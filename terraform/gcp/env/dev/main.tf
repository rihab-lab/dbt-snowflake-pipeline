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

#create landing & archive zone
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

##CLOUD RUN 
# ============================================================
# Cloud Run Job (dbt) - DEV
# ============================================================

############################
# 1️⃣ APIs
############################

resource "google_project_service" "run_api" {
  project            = local.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  project            = local.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

############################
# 2️⃣ Service Account
############################

resource "google_service_account" "dbt_job_sa" {
  project      = local.project_id
  account_id   = "sa-dbt-job-dev"
  display_name = "Service Account for dbt Cloud Run Job (dev)"
}

############################
# 3️⃣ IAM
############################

resource "google_project_iam_member" "dbt_job_artifact_reader" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.dbt_job_sa.email}"
}

resource "google_project_iam_member" "dbt_job_secret_accessor" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.dbt_job_sa.email}"
}

/*
resource "google_project_iam_member" "cloud_run_viewer_me" {
  project = local.project_id
  role    = "roles/run.viewer"
  member  = "user:rihab.bahri7@rbaapp.com"
}

resource "google_project_iam_member" "logging_viewer_me" {
  project = local.project_id
  role    = "roles/logging.viewer"
  member  = "user:rihab.bahri7@rbaapp.com"
}

resource "google_project_iam_member" "cloud_run_developer_me" {
  project = local.project_id
  role    = "roles/run.developer"
  member  = "user:rihab.bahri7@rbaapp.com"
}

############################
# 4️⃣ Secrets (containers)
############################

locals {
  snowflake_secrets = {
    account   = var.snowflake_account
    user      = var.snowflake_user
    password  = var.snowflake_password
    role      = var.snowflake_role
    warehouse = var.snowflake_warehouse
    database  = var.snowflake_database
    schema    = var.snowflake_schema
  }
}

resource "google_secret_manager_secret" "snowflake" {
  for_each  = local.snowflake_secrets
  project   = local.project_id
  secret_id = "snowflake-${each.key}-dev"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "snowflake_versions" {
  for_each    = local.snowflake_secrets
  secret      = google_secret_manager_secret.snowflake[each.key].id
  secret_data = each.value
}

############################
# 5️⃣ Cloud Run Job
############################

resource "google_cloud_run_v2_job" "dbt_run_dev" {
  project  = local.project_id
  location = var.region
  name     = "dbt-run-dev"

  template {
    template {
      service_account = google_service_account.dbt_job_sa.email

      containers {
        image = "europe-west1-docker.pkg.dev/${local.project_id}/ar-pipeone-dev/dbt:latest"

        # Inject secrets automatiquement
        dynamic "env" {
          for_each = google_secret_manager_secret.snowflake
          content {
            name = upper("SNOWFLAKE_${env.key}")
            value_source {
              secret_key_ref {
                secret  = env.value.secret_id
                version = "latest"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.run_api,
    google_project_iam_member.dbt_job_artifact_reader,
    google_project_iam_member.dbt_job_secret_accessor,
    google_secret_manager_secret_version.snowflake_versions
  ]
}*/