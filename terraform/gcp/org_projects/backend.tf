terraform {
  backend "gcs" {
    bucket = "tfstate-bootstrap-project-487710"
    prefix = "org-projects"
  }
}
