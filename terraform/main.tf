module "repos" {
  source = "./modules/repo"

  map_projects = local.map_projects
  map_repos    = local.map_repos
}

module "service_connections" {
  source = "./modules/serviceconn"

  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id
  projects        = module.repos.projects
  sonarqube_url   = local.sonar_endpoint
  sonarqube_token = local.sonar_token
}

module "build_defs" {
  source = "./modules/builddef"

  projects         = module.repos.projects
  repos            = module.repos.repos
  map_repos        = local.map_repos
  sonarqube_url    = local.sonar_endpoint
  svc_conn_azurerm = module.service_connections.service_connections_azurerm
}
