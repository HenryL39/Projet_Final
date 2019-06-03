###########################################################
#----------------------Public IPS-------------------------#
###########################################################
resource "azurerm_public_ip" "PIPs" {
    count                        = 3
    name                         = "${element(var.PIP_names, count.index)}"
    location                     = "${var.region}"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Network Interfaces-----------------#
###########################################################
resource "azurerm_network_interface" "NICs" {
    count               = 3
    name                = "${element(var.NIC_names, count.index)}"
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.NSG.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.Subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.PIPs.*.id, count.index)}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

###########################################################
#----------------------Random IDS-------------------------#
###########################################################
resource "random_id" "randomIds" {
    count       = 3
    keepers {
		resource_group = "${azurerm_resource_group.myterraformgroup.name}"
	}
    
    byte_length = 8
}

###########################################################
#----------------------Virtual Machines-------------------#
###########################################################
resource "azurerm_virtual_machine" "VMs" {
    count                 = 3
    name                  = "${element(var.VM_names, count.index)}"
    location              = "${var.region}"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${element(azurerm_network_interface.NICs.*.id, count.index)}"]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "${element(var.storage_names, count.index)}"
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
        computer_name  = "${element(var.VM_names, count.index)}"
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