resource "azuredevops_serviceendpoint_azurerm" "svc_connection" {
  for_each = var.projects

  project_id                             = each.value.id
  service_endpoint_name                  = "svcconn-azurerm-${each.value.id}"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.subscription_id
}

resource "azuredevops_serviceendpoint_sonarqube" "per_project" {
  for_each = var.projects

  project_id            = each.value.id
  service_endpoint_name = "svcconn-sonar-${each.key}"
  url                   = var.sonarqube_url
  token                 = var.sonarqube_token
}
