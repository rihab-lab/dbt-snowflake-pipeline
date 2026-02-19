terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }

  # Backend GCS configuré via la CI avec -backend-config
  backend "gcs" {}
}
