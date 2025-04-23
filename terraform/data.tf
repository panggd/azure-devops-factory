data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "kv_devops_factory" {
  name                = local.kv_name_devops_factory
  resource_group_name = local.devops_factory_resource_group
}

data "azurerm_key_vault_secret" "sonar_token" {
  name         = local.kv_secret_sonar_token
  key_vault_id = data.azurerm_key_vault.kv_devops_factory.id
}
