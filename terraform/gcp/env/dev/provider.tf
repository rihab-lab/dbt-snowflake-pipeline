terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}

provider "google" {
  project               = var.bootstrap_project_id
  billing_project       = var.bootstrap_project_id
  user_project_override = true
}
