output "projects_map" {
  value = {
    for env, project_id in local.projects :
    env => project_id
  }
}

output "project_numbers" {
  value = {
    for env, prj in google_project.project :
    env => prj.number
  }
}
