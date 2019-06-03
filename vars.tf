variable "region" {}
variable "subnet_name" {}
variable "resource_group_name" {}
variable "NSG_name" {}
variable "vnet_name" {}
variable "jenkins_PIP_name" {}
variable "ssh_port" {}
variable "jenkins_port" {}
variable "jenkins_NIC_name" {}
variable "jenkins_VM_name" {}
variable "sub_adress" {}
variable "vnet_address" {}
variable "os_disk_name" {}



variable "PIP_names" {
    type = "list"
    default = ["docker-PIP", "nexus-PIP", "apache-PIP"]
}

variable "NIC_names" {
    type = "list"
    default = ["docker-NIC", "nexus-NIC", "apache-NIC"]
}

variable "VM_names" {
    type = "list"
    default = ["docker-VM", "nexus-VM", "apache-VM"]
}

variable "storage_names" {
    type = "list"
    default = ["docker-os-disk", "nexus-os-disk", "apache-os-disk"]
}