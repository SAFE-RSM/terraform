terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
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

data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

locals {
  mon_ip_publique = chomp(data.http.myip.response_body)
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

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  location            = azurerm_virtual_network.example.location
  resource_group_name = azurerm_virtual_network.example.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "ubuterra-sfernandes2024"

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_virtual_network.example.location
  resource_group_name = azurerm_virtual_network.example.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${local.mon_ip_publique}/32"
    destination_address_prefix = "*"
  }

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_network_interface" "example_dynamic" {
  name                = "exampleni"
  location            = azurerm_virtual_network.example.location
  resource_group_name = azurerm_virtual_network.example.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.exSUBNET.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example_dynamic.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_linux_virtual_machine" "example" {
  name                            = "ubuterra"
  resource_group_name             = "rg-SFernandesmartins2024_cours-terraform"
  location                        = azurerm_virtual_network.example.location
  size                            = "Standard_B1ls"
  admin_username                  = "adminuser"
  computer_name                   = "ubuterra"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.example_dynamic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    user = "SFernandesmartins2024"
  }
}


output "ssh_command" {
  value       = "ssh ${azurerm_linux_virtual_machine.example.admin_username}@${azurerm_public_ip.example.fqdn}"
  description = "Commande pour se connecter en SSH à la VM"
}
