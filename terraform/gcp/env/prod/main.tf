module "project" {
  source             = "../../modules/org_projects"
  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  project_prefix = "snowdbt"
  environments   = ["prod"]

  labels = {
    environment = "prod"
    managed_by  = "terraform"
  }
}

# On récupère l'ID du projet créé
locals {
  project_id = module.project.projects_map["prod"]
}

# Bucket landing
resource "google_storage_bucket" "landing" {
  name                        = "bck-pipeone-landing-prod"
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
  name                        = "bck-pipeone-archive-prod"
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