###########################################################
#----------------------Ressource Group--------------------#
###########################################################

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "${var.resource_group_name}"
    location = "${var.region}"

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Virtual Network--------------------#
###########################################################

resource "azurerm_virtual_network" "Vnet" {
    name                = "${var.vnet_name}"
    address_space       = ["${var.vnet_address}"]
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Subnetwork-------------------------#
###########################################################

resource "azurerm_subnet" "Subnet" {
    name                 = "${var.subnet_name}"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.Vnet.name}"
    address_prefix       = "${var.sub_adress}"
}

###########################################################
#----------------------Public IP--------------------------#
###########################################################

resource "azurerm_public_ip" "JenkinsPIP" {
    name                         = "${var.jenkins_PIP_name}"
    location                     = "${var.region}"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Security Group---------------------#
###########################################################

resource "azurerm_network_security_group" "NSG" {
    name                = "${var.NSG_name}"
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "${var.ssh_port}"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "JENKINS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "${var.jenkins_port}"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Network Interface------------------#
###########################################################

resource "azurerm_network_interface" "JenkinsNIC" {
    name                = "${var.jenkins_NIC_name}"
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.NSG.id}"

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = "${azurerm_subnet.Subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.JenkinsPIP.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Random ID--------------------------#
###########################################################

resource "random_id" "randomId" {
    keepers {
		resource_group = "${azurerm_resource_group.myterraformgroup.name}"
	}
    
    byte_length = 8
}

###########################################################
#----------------------Virtual Machine--------------------#
###########################################################

resource "azurerm_virtual_machine" "JenkinsVM" {
    name                  = "${var.jenkins_VM_name}"
    location              = "${var.region}"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.JenkinsNIC.id}"]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "${var.os_disk_name}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.jenkins_VM_name}"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/loFdLgNMVS5xbaZubYj/0EBhQxq/MlqsgcoJpjDiXYyDsDrmMqPBCR3n0516DBJfYXG5wXeKik6h60vJscDp27z1DNkAHBxgLUYErOvMkftEyHnb+KeoI3AtmKvpn9wozENHP9VqmSmbv+h0zASK0MJjkxQxsZVAZTPNDJIdW9cFBgx9KRLD4Xct7c+VhToQeaWG/ChQszsyC7uT7YAsIQVAVBpRPiiQ1H4+nrj43KwrtAYSSNcRhEppsZCS0QVzrgBJ98DrvLfv2qDLuFGZ34AyzNtS7ZVrii+NU6n0a80pIYMFy/dZUbnwRP4tKuq8eyF/uBlk+I7NyvDeEZcN henry@linux-3.home"
        }
    }

    tags {
        environment = "Terraform Demo"
    }
}