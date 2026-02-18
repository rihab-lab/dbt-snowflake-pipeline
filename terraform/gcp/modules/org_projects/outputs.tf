output "projects_map" {
  value = {
    for env, pid in local.projects :
    env => pid
  }
}

output "project_numbers" {
  value = {
    for env, prj in google_project.env :
    env => prj.number
  }
}
