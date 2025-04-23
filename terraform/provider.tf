terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "1.8.1"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/${var.org_id}"
}
