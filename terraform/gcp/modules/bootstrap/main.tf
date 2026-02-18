data "google_project" "bootstrap" {
  project_id = var.bootstrap_project_id
}

resource "google_service_account" "ci" {
  project      = var.bootstrap_project_id
  account_id   = var.ci_service_account_id
  display_name = "GitHub Actions Terraform (bootstrap)"

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool" "pool" {
  project                   = var.bootstrap_project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  project                            = var.bootstrap_project_id
  workload_identity_pool_id           = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id  = "github-provider"
  display_name                        = "GitHub OIDC Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = format(
    "attribute.repository == '%s/%s' && attribute.ref == '%s'",
    var.github_owner,
    var.github_repo,
    var.allowed_ref
  )

  depends_on = [
    google_project_service.required,
    google_iam_workload_identity_pool.pool
  ]
}

resource "google_service_account_iam_member" "wif_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"

  member = format(
    "principalSet://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s/attribute.repository/%s/%s",
    data.google_project.bootstrap.number,
    google_iam_workload_identity_pool.pool.workload_identity_pool_id,
    var.github_owner,
    var.github_repo
  )

  depends_on = [
    google_service_account.ci,
    google_iam_workload_identity_pool_provider.provider
  ]
}

resource "google_organization_iam_member" "ci_project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.ci.email}"

  depends_on = [google_service_account.ci]
}

resource "google_billing_account_iam_member" "ci_billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.ci.email}"

  depends_on = [google_service_account.ci]
}

