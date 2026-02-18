output "ci_service_account_email" {
  value = google_service_account.ci.email
}

output "wif_provider" {
  value = format(
    "projects/%s/locations/global/workloadIdentityPools/%s/providers/%s",
    data.google_project.bootstrap.number,
    google_iam_workload_identity_pool.pool.workload_identity_pool_id,
    google_iam_workload_identity_pool_provider.provider.workload_identity_pool_provider_id
  )
}

output "tfstate_bucket_name" {
  value = google_storage_bucket.tfstate.name
}

