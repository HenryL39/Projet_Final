variable "gcp-projet-id" {}
variable "gcp-region" {}
variable "gcp-zone" {}
variable "gcp-test-firewall" {}
variable "gcp-prod-firewall" {}
variable "gcp-test-vnet" {}
variable "gcp-prod-vnet" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "gcp-test-vm" {}
variable "gcp-prod-vm" {}

variable "gcp-test-cluster" {}
variable "gcp-prod-cluster" {}
variable "gcp-test-cluster-cidr" {}
variable "gcp-prod-cluster-cidr" {}
variable "gcp-test-master-cidr" {}
variable "gcp-prod-master-cidr" {}
variable "gcp-test-nodes" {}
variable "gcp-prod-nodes" {}

variable "gcp-test-subnet" {
    type = "list"
    default = ["test-database-subnet", "test-kubernetes-subnet"]
}
variable "gcp-prod-subnet" {
    type = "list"
    default = ["prod-database-subnet", "prod-kubernetes-subnet"]
}
variable "gcp-test-subnet-cidr" {
    type = "list"
    default = ["10.1.0.0/16", "10.2.0.0/16"]
}
variable "gcp-prod-subnet-cidr" {
    type = "list"
    default = ["10.3.0.0/16", "10.4.0.0/16"]
}