resource "azurerm_virtual_network" "vnethub" {
  name                = "vnet-hub"
  location            = var.locationrg
  resource_group_name = var.Rg_name
  address_space       = ["10.0.1.0/24"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_subnet" "Firewallpub" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.vnethub.name
  address_prefixes     = ["10.0.1.0/26"] # IP: 10.0.1.0 - 10.0.1.63
}

resource "azurerm_subnet" "Firewallpriv" {
  name                 = "Firewall-priv"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.vnethub.name
  address_prefixes     = ["10.0.1.64/28"] # IP: 10.0.1.64 - 10.0.1.79
}

resource "azurerm_subnet" "Ressources" {
  name                 = "Ressources"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.vnethub.name
  address_prefixes     = ["10.0.1.80/28"] # IP: 10.0.1.80 - 10.0.1.95
}

####RSX2####

resource "azurerm_virtual_network" "vnetspokeDevopsTools" {
  name                = "vnet-spoke-DevopsTools"
  location            = var.locationrg
  resource_group_name = var.Rg_name
  address_space       = ["10.0.2.0/24"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.vnetspokeDevopsTools.name
  address_prefixes     = ["10.0.2.0/26"] # IP: 10.0.2.0 - 10.0.2.63
}

resource "azurerm_subnet" "DockerInstancesDevops" {
  name                 = "DockerInstances"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.vnetspokeDevopsTools.name
  address_prefixes     = ["10.0.2.64/28"] # IP: 10.0.2.64 - 10.0.2.79 

  # Délégation pour Azure Container Instances
  delegation {
    name = "aci_delegation_devops"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

####RSX3####

resource "azurerm_virtual_network" "Vnetspokewordpressprod" {
  name                = "Vnet-spoke-wordpress-prod"
  location            = var.locationrg
  resource_group_name = var.Rg_name
  address_space       = ["10.0.3.0/24"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_subnet" "MysqlFlexiblesServers" {
  name                 = "MysqlFlexiblesServers"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.Vnetspokewordpressprod.name
  address_prefixes     = ["10.0.3.0/28"] # IP: 10.0.3.0 - 10.0.3.15

  # Délégation pour MySQL Flexible Server
  delegation {
    name = "mysql_delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "DockerInstancesProd" {
  name                 = "DockerInstances"
  resource_group_name  = var.Rg_name
  virtual_network_name = azurerm_virtual_network.Vnetspokewordpressprod.name
  address_prefixes     = ["10.0.3.16/28"] # IP: 10.0.3.16 - 10.0.3.31 

  # Délégation pour Azure Container Instances
  delegation {
    name = "aci_delegation_prod"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_devops" {
  name                         = "hub_to_spoke_devops"
  resource_group_name          = var.Rg_name
  virtual_network_name         = azurerm_virtual_network.vnethub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnetspokeDevopsTools.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_devops_to_hub" {
  name                         = "spoke_devops_to_hub"
  resource_group_name          = var.Rg_name
  virtual_network_name         = azurerm_virtual_network.vnetspokeDevopsTools.name
  remote_virtual_network_id    = azurerm_virtual_network.vnethub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_wordpress" {
  name                         = "hub_to_spoke_wordpress"
  resource_group_name          = var.Rg_name
  virtual_network_name         = azurerm_virtual_network.vnethub.name
  remote_virtual_network_id    = azurerm_virtual_network.Vnetspokewordpressprod.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_wordpress_to_hub" {
  name                         = "spoke_wordpress_to_hub"
  resource_group_name          = var.Rg_name
  virtual_network_name         = azurerm_virtual_network.Vnetspokewordpressprod.name
  remote_virtual_network_id    = azurerm_virtual_network.vnethub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}


resource "azurerm_network_security_group" "spoke-devops-tools" {
  name                = "spoke-devops-tools-nsg"
  location            = azurerm_virtual_network.vnetspokeDevopsTools.location
  resource_group_name = var.Rg_name

  security_rule {
    name                       = "spoke-devops-tools-nsg-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "spoke-devops-tools-nsg-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_network_security_group" "spoke-wordpress-prod" {
  name                = "spoke-wordpress-prod-nsg"
  location            = azurerm_virtual_network.Vnetspokewordpressprod.location
  resource_group_name = var.Rg_name

  security_rule {
    name                       = "spoke-wordpress-prod-nsg-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "spoke-wordpress-prod-nsg-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    user = "SFernandesmartins2024"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.spoke-devops-tools.id
}

resource "azurerm_subnet_network_security_group_association" "docker-devops" {
  subnet_id                 = azurerm_subnet.DockerInstancesDevops.id
  network_security_group_id = azurerm_network_security_group.spoke-devops-tools.id
}

resource "azurerm_subnet_network_security_group_association" "MysqlFlexiblesServers" {
  subnet_id                 = azurerm_subnet.MysqlFlexiblesServers.id
  network_security_group_id = azurerm_network_security_group.spoke-wordpress-prod.id
}

resource "azurerm_subnet_network_security_group_association" "DockerInstancesProd" {
  subnet_id                 = azurerm_subnet.DockerInstancesProd.id
  network_security_group_id = azurerm_network_security_group.spoke-wordpress-prod.id
}

resource "azurerm_private_dns_zone" "interne" {
  name                = "monprojet.interne.azure"
  resource_group_name = var.Rg_name
  tags = {
    user = "SFernandesmartins2024"
  }
}

# Lier aux 3 VNets avec count (plus concis que 3 ressources)
resource "azurerm_private_dns_zone_virtual_network_link" "interne_links" {
  count                 = 3
  resource_group_name   = var.Rg_name
  name                  = "interne-link-${count.index + 1}"
  private_dns_zone_name = azurerm_private_dns_zone.interne.name
  virtual_network_id = element([
    azurerm_virtual_network.vnethub.id,
    azurerm_virtual_network.vnetspokeDevopsTools.id,
    azurerm_virtual_network.Vnetspokewordpressprod.id
  ], count.index)
  registration_enabled = true # Enregistrement auto des VMs !
  tags = {
    user = "SFernandesmartins2024"
  }
}
