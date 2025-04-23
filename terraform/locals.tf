locals {

  # key vault
  devops_factory_resource_group = "rg_devops_factory"
  kv_name_devops_factory        = "kv-devops-factory"
  kv_secret_sonar_token         = "sonar-token"

  sonar_endpoint = "https://sonarqube.myorg.com" # to replace with actual sonarqube server url
  sonar_token    = try(data.azurerm_key_vault_secret.sonar_token.value, null)

  map_repos = {
    for repo in flatten([
      for project_name, project in var.definition : [
        for repo_name, repo in project.repos : {
          project_key  = project_name
          repo_name    = repo_name
          repo_lang    = repo.language
          repo_appName = repo.appName
        }
      ]
    ]) : "${repo.project_key}_${repo.repo_name}" => repo
  }

  map_projects = tomap({
    for project_name, project in var.definition :
    project_name => project_name
  })
}
