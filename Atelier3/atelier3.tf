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

data "azurerm_resource_group" "example" {
  name = "rg-SFernandesmartins2024_cours-terraform"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  location            = "francecentral"
  resource_group_name = "rg-SFernandesmartins2024_cours-terraform"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_subnet" "exSUBNET" {
  name                 = "example-subnet"
  resource_group_name  = "rg-SFernandesmartins2024_cours-terraform"
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}
