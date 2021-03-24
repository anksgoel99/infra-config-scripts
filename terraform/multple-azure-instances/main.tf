provider "azurerm" {
   features {}
   subscription_id = "6b20b04f-9b29-4327-88b8-9fdabb8552b7"
}

resource "azurerm_resource_group" "ankit-tf-RG" {
  name     = "ankit-perf-RG-TF"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "azure_VN" {
    name = "${var.prefix}-VN"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
   resource_group_name = azurerm_resource_group.ankit-tf-RG.name
}

resource "azurerm_subnet" "azure_subnet" {
   name = "${var.prefix}-subnet"
   resource_group_name = azurerm_resource_group.ankit-tf-RG.name
   virtual_network_name = azurerm_virtual_network.azure_VN.name
   address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "azure_win_publicIP" {
  name = "${var.prefix}-publicIP-${count.index + 1}"
  location = "${var.location}"
  resource_group_name = azurerm_resource_group.ankit-tf-RG.name
  allocation_method = "Dynamic"
  tags = {
    environment = "${var.tags}"
  }
  count = "${var.vm_count}"
}
resource "azurerm_network_security_group" "azure_nsg" {
    name = "${var.prefix}-nsg-${count.index + 1}"
    location = "${var.location}"
    resource_group_name = azurerm_resource_group.ankit-tf-RG.name
    
    security_rule = [ {
      access = "Allow"
      description = ""
      destination_address_prefixes = null
      destination_application_security_group_ids = null
      destination_port_ranges = null
      destination_address_prefix = "*"
      destination_port_range = "3389"
      direction = "Inbound"
      name = "RDP-${count.index + 1}"
      priority = 100
      protocol = "Tcp"
      source_address_prefixes = ["106.192.0.0/16","1.39.0.0/16","27.59.0.0/16","106.204.0.0/16"]
      source_application_security_group_ids = null
      source_port_range = "*"
      source_address_prefix = null
      source_port_ranges = null

    } ]

    tags = {
    environment = "${var.tags}"
  }
    count = "${var.vm_count}"
}
resource "azurerm_network_interface" "azure_win_net_Int" {
  name = "${var.prefix}-win-Nic-${count.index + 1}"
  location = "${var.location}"
  resource_group_name = azurerm_resource_group.ankit-tf-RG.name

  ip_configuration {
     name = "${var.prefix}-win-ip-${count.index + 1}"
     subnet_id = azurerm_subnet.azure_subnet.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id = azurerm_public_ip.azure_win_publicIP[count.index].id
   }
  count = "${var.vm_count}"
}

resource "azurerm_network_interface_security_group_association" "azure_nic_nsg_association" {
    count = length(azurerm_public_ip.azure_win_publicIP)
    network_interface_id = "${azurerm_network_interface.azure_win_net_Int[count.index].id}"
    network_security_group_id = "${azurerm_network_security_group.azure_nsg[count.index].id}"

  
}
resource "azurerm_windows_virtual_machine" "ank_perf_winvm" {
  name = "${var.prefix}-winvm-${count.index + 1}"
  location = "${var.location}"
  resource_group_name = azurerm_resource_group.ankit-tf-RG.name
  admin_username      = "ankit"
  admin_password      = "Password@123"
  network_interface_ids =  [azurerm_network_interface.azure_win_net_Int[count.index].id]
  size = "${var.win_vm_size}"
  
os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }
  count = "${var.vm_count}" 
}
