terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.3.0"
    }
  }
  backend "local" {
    path = "./atelier2.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "ca5c57dd-3aab-4628-a78c-978830d03bbd"
}

data "azurerm_resource_group" "az_group" {
  name = "rg-SFernandesmartins2024_cours-terraform"
}

output "id" {
  value = data.azurerm_resource_group.az_group.id
}
