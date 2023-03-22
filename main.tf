terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

}


resource "azurerm_resource_group" "terrademo-rg" {
  name     = "terademo-resources"
  location = "West Europe"
  tags = {
    environment = "DevDemo"
  }
}

resource "azurerm_virtual_network" "terra-vn" {
  name                = "terra-network"
  resource_group_name = azurerm_resource_group.terrademo-rg.name
  address_space       = ["10.0.1.0/24"]
  location            = azurerm_resource_group.terrademo-rg.location

  tags = {
    environment = "DevDemo"
  }
}

resource "azurerm_subnet" "terra-subnet" {
  name                 = "terra-subnet"
  resource_group_name  = azurerm_resource_group.terrademo-rg.name
  virtual_network_name = azurerm_virtual_network.terra-vn.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "tera-nsg" {
  name                = "myterra-nsg"
  location            = azurerm_resource_group.terrademo-rg.location
  resource_group_name = azurerm_resource_group.terrademo-rg.name
  tags = {
    environment = "DevDemo"
  }
}
resource "azurerm_network_security_rule" "terra-dev-rule" {
  name                        = "terra-devr-ule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terrademo-rg.name
  network_security_group_name = azurerm_network_security_group.tera-nsg.name
}
resource "azurerm_subnet_network_security_group_association" "terra-sga" {
  subnet_id                 = azurerm_subnet.terra-subnet.id
  network_security_group_id = azurerm_network_security_group.tera-nsg.id
}

resource "azurerm_public_ip" "terra-ip" {
  name                = "terra-ip"
  resource_group_name = azurerm_resource_group.terrademo-rg.name
  location            = azurerm_resource_group.terrademo-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "DevDemo"
  }
}

resource "azurerm_network_interface" "terra-nic" {
  name                = "terra-nic"
  location            = azurerm_resource_group.terrademo-rg.location
  resource_group_name = azurerm_resource_group.terrademo-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terra-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terra-ip.id


  }
}

resource "azurerm_linux_virtual_machine" "terraVM" {
  name                = "terraVM"
  resource_group_name = azurerm_resource_group.terrademo-rg.name
  location            = azurerm_resource_group.terrademo-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terra-nic.id,
  ]
  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/teraazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  tags = {
    environment = "DevDemo"
  }
}

