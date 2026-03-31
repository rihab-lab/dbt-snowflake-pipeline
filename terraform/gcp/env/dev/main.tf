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
resource "google_storage_bucket_iam_member" "landing_viewer" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.bucketViewer"
  member = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_storage_bucket.landing]
}
#to be addded storage.bucketViewer
resource "google_storage_bucket_iam_member" "archive_admin" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_storage_bucket.archive]
}
resource "google_storage_bucket_iam_member" "archive_viewer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_storage_bucket.archive]
}
#composer
# ------------------------------------------------------------
# APIs requises (Composer + dépendances)
# ------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    #"composer.googleapis.com",
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

resource "google_project_service" "composer_api" {
  count              = var.enable_composer ? 1 : 0
  project            = local.project_id
  service            = "composer.googleapis.com"
  disable_on_destroy = false
}
# ------------------------------------------------------------
# Cloud Composer 2 - Service Agent Extension role (OBLIGATOIRE)
# service-<PROJECT_NUMBER>@cloudcomposer-accounts.iam.gserviceaccount.com
# ------------------------------------------------------------
resource "google_project_iam_member" "composer_service_agent_v2ext" {
  count   = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${module.project.project_numbers["dev"]}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# ------------------------------------------------------------
# Google APIs Service Account - souvent requis pour Composer
# <PROJECT_NUMBER>@cloudservices.gserviceaccount.com
# ------------------------------------------------------------
resource "google_project_iam_member" "cloudservices_editor" {
  count   = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${module.project.project_numbers["dev"]}@cloudservices.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}

# ------------------------------------------------------------
# Attendre propagation IAM (évite les erreurs 400 "missing perms")
# ------------------------------------------------------------
resource "time_sleep" "wait_composer_iam" {
  count   = var.enable_composer ? 1 : 0
  depends_on      = [
    google_project_iam_member.composer_service_agent_v2ext,
    google_project_iam_member.cloudservices_editor
  ]
  create_duration = "60s"
}

# ------------------------------------------------------------
# Service Account pour l'environnement Composer (workers)
# ------------------------------------------------------------
resource "google_service_account" "composer" {
  count   = var.enable_composer ? 1 : 0
  project      = local.project_id
  account_id   = "sa-composer-dev"
  display_name = "Composer SA (dev)"

  depends_on = [google_project_service.apis]
}

# Composer workers role (obligatoire)
resource "google_project_iam_member" "composer_worker_role" {
  count  = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer[0].email}"

  depends_on = [google_service_account.composer]
}

# ------------------------------------------------------------
# IAM buckets (landing/archive)
# ------------------------------------------------------------
resource "google_storage_bucket_iam_member" "landing_viewer_composer" {
  count  = var.enable_composer ? 1 : 0
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_storage_bucket_iam_member" "archive_admin_composer" {
  count  = var.enable_composer ? 1 : 0
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.composer[0].email}"
}

# Optionnel : accès secrets (Snowflake/dbt) si tu utilises Secret Manager
resource "google_project_iam_member" "composer_secret_accessor" {
  count  = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.composer[0].email}"
}

# Accès UI Composer pour ton user (console + liste env)
resource "google_project_iam_member" "composer_user_me" {
  count  = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/composer.user"
  member  = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_project_service.apis]
}

# ------------------------------------------------------------
# Composer Environment DEV
# ------------------------------------------------------------
resource "google_composer_environment" "dev" {
  count   = var.enable_composer ? 1 : 0
  project = local.project_id
  name    = "composer-pipeone-dev"
  region  = var.region

  depends_on = [
    time_sleep.wait_composer_iam,
    google_project_iam_member.composer_worker_role,
    google_storage_bucket_iam_member.landing_viewer_composer,
    google_storage_bucket_iam_member.archive_admin_composer
  ]

  config {
    node_config {
      service_account = google_service_account.composer[0].email
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
        min_count  = 0
        max_count  = 2
      }
    }
  }
}


# Accès Monitoring (sinon page surveillance bloquée)
resource "google_project_iam_member" "monitoring_viewer_me" {
  count   = var.enable_composer ? 1 : 0
  project = local.project_id
  role    = "roles/monitoring.viewer"
  member  = "user:rihab.bahri7@rbaapp.com"

  depends_on = [google_project_service.apis]
}

# Accès à ton user pour lire/voir les DAGs dans le bucket Composer
resource "google_storage_bucket_iam_member" "composer_bucket_viewer_me" {
  count   = var.enable_composer ? 1 : 0
  bucket = "europe-west1-composer-pipeo-f6eee988-bucket"
  role   = "roles/storage.objectViewer"
  member = "user:rihab.bahri7@rbaapp.com"
}

# Pour uploader/modifier les DAGs (recommandé si tu veux déposer des fichiers)
resource "google_storage_bucket_iam_member" "composer_bucket_admin_me" {
  count   = var.enable_composer ? 1 : 0
  bucket = "europe-west1-composer-pipeo-f6eee988-bucket"
  role   = "roles/storage.objectAdmin"
  member = "user:rihab.bahri7@rbaapp.com"
}



resource "google_storage_bucket_iam_member" "composer_bucket_admin_ci" {
  bucket = "europe-west1-composer-pipeo-f6eee988-bucket"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.ci_service_account_email}"
}

# Active l'API Artifact Registry
resource "google_project_service" "artifactregistry_api" {
  project            = local.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Repo Docker pour stocker l'image dbt
resource "google_artifact_registry_repository" "docker_repo" {
  project       = local.project_id
  location      = var.region            # europe-west1
  repository_id = "ar-pipeone-dev"
  format        = "DOCKER"
  description   = "Docker images for PipeOne (dev)"

  depends_on = [google_project_service.artifactregistry_api]
}

resource "google_artifact_registry_repository_iam_member" "ci_writer" {
  project    = local.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

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

#new one 
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
}