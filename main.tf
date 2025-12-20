terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "backend-rg"
    storage_account_name = "backendstrg"
    container_name       = "santcontainer"
    key                  = "agent.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "fa3325aa-2291-472e-9d80-68f554038ffc"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-ado-agent"
  location = "Japan East"
}

# VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ado-agent"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-agent"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ado-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Subnet NSG association
resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "pip-ado-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC
resource "azurerm_network_interface" "nic" {
  name                = "nic-ado-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Linux VM
resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                            = "ado-agent-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "santosh"
  admin_password                  = "Santosh@1234"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.sh", {
    ado_org_url = var.ado_org_url
    ado_pat     = var.ado_pat
    agent_pool  = var.agent_pool
    agent_name  = "agent-${random_string.suffix.result}"
  }))
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}
