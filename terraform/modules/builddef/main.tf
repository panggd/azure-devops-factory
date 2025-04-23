resource "azuredevops_build_definition" "builddef_branch_dev" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = var.projects[each.value.project_key].id
  path       = "\\${each.value.repo_name}"
  name       = "dev"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = var.repos[each.key].id
    yml_path    = "definitions/azure-pipeline-dev-${each.value.repo_lang}.yml"
    branch_name = "refs/heads/dev"
  }

  variable {
    name  = "webAppName"
    value = each.value.repo_appName
  }

  variable {
    name  = "sonarQubeEndpoint"
    value = var.sonarqube_url
  }

  variable {
    name  = "sonarProjectKey"
    value = each.value.repo_appName
  }

  variable {
    name  = "svcConnAzurerm"
    value = var.svc_conn_azurerm["svcconn-azurerm-${var.projects[each.value.project_key].id}"].name
  }
}

# add branch level build definition, pointing to a standardized azure pipeline yml for stg
resource "azuredevops_build_definition" "builddef_branch_stg" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = var.projects[each.value.project_key].id
  path       = "\\${each.value.repo_name}"
  name       = "stg"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = var.repos[each.key].id
    yml_path    = "definitions/azure-pipeline-stg-${each.value.repo_lang}.yml"
    branch_name = "refs/heads/stg"
  }

  variable {
    name  = "svcConnAzurerm"
    value = var.svc_conn_azurerm["svcconn-azurerm-${var.projects[each.value.project_key].id}"].name
  }
}

# add branch level build definition, pointing to a standardized azure pipeline yml for prd (separate tenant)
resource "azuredevops_build_definition" "builddef_branch_prd" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = var.projects[each.value.project_key].id
  path       = "\\${each.value.repo_name}"
  name       = "prd"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = var.repos[each.key].id
    yml_path    = "definitions/azure-pipeline-prd-${each.value.repo_lang}.yml"
    branch_name = "refs/heads/main"
  }

  variable {
    name  = "stgPipelineId"
    value = azuredevops_build_definition.builddef_branch_stg["${each.key}"].id
  }

  variable {
    name  = "svcConnAzurerm"
    value = var.svc_conn_azurerm["svcconn-azurerm-${var.projects[each.value.project_key].id}"].name
  }
}
