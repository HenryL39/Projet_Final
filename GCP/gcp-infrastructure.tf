###########################################################
#----------------------Provider---------------------------#
###########################################################

provider "google" {
    credentials     = "${file("credentials_gcp.json")}"
    project         = "${var.gcp-projet-id}"
    region          = "${var.gcp-region}"
    zone            = "${var.gcp-zone}"
}

###########################################################
#----------------------firewall---------------------------#
###########################################################

resource "google_compute_firewall" "firewall-test" {
  name    = "${var.gcp-test-firewall}"
  network = "${google_compute_network.vnet-test.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "27017"]
  }

  priority = 1000
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "firewall-prod" {
  name    = "${var.gcp-prod-firewall}"
  network = "${google_compute_network.vnet-prod.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "27017"]
  }

  priority = 1000
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "firewall-test-out" {
  name    = "${var.gcp-test-out-firewall}"
  network = "${google_compute_network.vnet-test.name}"

  deny {
    protocol = "tcp"
  }

  direction = "EGRESS"
  priority = 20
  destination_ranges = ["10.2.0.0/16","10.5.0.0/28"]
}

resource "google_compute_firewall" "firewall-prod-out" {
  name    = "${var.gcp-prod-out-firewall}"
  network = "${google_compute_network.vnet-prod.name}"

  deny {
    protocol = "tcp"
  }

  direction = "EGRESS"
  priority = 20
  destination_ranges = ["10.5.0.0/16","10.6.0.0/28"]
}


###########################################################
#----------------------Cluster----------------------------#
###########################################################

resource "google_container_cluster" "test-cluster" {
  name     = "${var.gcp-test-cluster}"
  location = "${var.gcp-zone}"
  network    = "${google_compute_network.vnet-test.self_link}"
  subnetwork = "${element(google_compute_subnetwork.subnet-test.*.self_link, 1)}"
  initial_node_count = 1

  ip_allocation_policy {
    node_ipv4_cidr_block = "${var.gcp-test-cluster-cidr}"
  }

  private_cluster_config {
    master_ipv4_cidr_block = "${var.gcp-test-master-cidr}"
  }

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  node_config {
     oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_cluster" "prod-cluster" {
  name     = "${var.gcp-prod-cluster}"
  location = "${var.gcp-zone}"
  network    = "${google_compute_network.vnet-prod.self_link}"
  subnetwork = "${element(google_compute_subnetwork.subnet-prod.*.self_link, 1)}"
  initial_node_count = 1

  ip_allocation_policy {
    node_ipv4_cidr_block = "${var.gcp-prod-cluster-cidr}"
  }

  private_cluster_config {
    master_ipv4_cidr_block = "${var.gcp-prod-master-cidr}"
  }

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  node_config {
     oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


###########################################################
#----------------------NAT--------------------------------#
###########################################################

resource "google_compute_router" "router-test" {
  name    = "${var.test-router}"
  region  = "${var.gcp-region}"
  network = "${google_compute_network.vnet-test.self_link}"
  bgp {
    asn = 64514
  }
}

resource "google_compute_router" "router-prod" {
  name    = "${var.prod-router}"
  region  = "${var.gcp-region}"
  network = "${google_compute_network.vnet-prod.self_link}"
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "test-nat" {
  name                               = "${var.test-nat}"
  router                             = "${google_compute_router.router-test.name}"
  region                             = "${var.gcp-region}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_router_nat" "prod-nat" {
  name                               = "${var.prod-nat}"
  router                             = "${google_compute_router.router-prod.name}"
  region                             = "${var.gcp-region}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

###########################################################
#----------------------Node Pool--------------------------#
###########################################################

// resource "google_container_node_pool" "test-nodes" {
//   name       = "${var.gcp-test-nodes}"
//   location   = "${var.gcp-zone}"
//   cluster    = "${google_container_cluster.test-cluster.name}"
//   node_count = 1

//   node_config {
//     preemptible  = true
//     machine_type = "n1-standard-1"

//     metadata {
//       disable-legacy-endpoints = "true"
//     }

//     oauth_scopes = [
//       "https://www.googleapis.com/auth/compute",
//       "https://www.googleapis.com/auth/devstorage.read_only",
//       "https://www.googleapis.com/auth/logging.write",
//       "https://www.googleapis.com/auth/monitoring",
//     ]
//   }
// }

// resource "google_container_node_pool" "prod-nodes" {
//   name       = "${var.gcp-prod-nodes}"
//   location   = "${var.gcp-zone}"
//   cluster    = "${google_container_cluster.prod-cluster.name}"
//   node_count = 1

//   node_config {
//     preemptible  = true
//     machine_type = "n1-standard-1"

//     metadata {
//       disable-legacy-endpoints = "true"
//     }

//     oauth_scopes = [
//       "https://www.googleapis.com/auth/compute",
//       "https://www.googleapis.com/auth/devstorage.read_only",
//       "https://www.googleapis.com/auth/logging.write",
//       "https://www.googleapis.com/auth/monitoring",
//     ]
//   }
// }


###########################################################
#----------------------Load Balancer----------------------#
###########################################################

resource "google_compute_forwarding_rule" "test-load-balancer" {
  name       = "${var.gcp-test-lb}"
  target     = "${google_compute_target_pool.test-target-pool.self_link}"
}

resource "google_compute_target_pool" "test-target-pool" {
  name = "${var.gcp-test-target-pool}"

  instances = [
    "${var.gcp-zone}/${var.gcp-test-nodes}",
  ]
}

resource "google_compute_forwarding_rule" "prod-load-balancer" {
  name       = "${var.gcp-prod-lb}"
  target     = "${google_compute_target_pool.prod-target-pool.self_link}"
}

resource "google_compute_target_pool" "prod-target-pool" {
  name = "${var.gcp-prod-target-pool}"

  instances = [
    "${var.gcp-zone}/${var.gcp-prod-nodes}",
  ]
}

###########################################################
#----------------------Subnets----------------------------#
###########################################################

resource "google_compute_subnetwork" "subnet-test" {
  count         = 2
  name          = "${element(var.gcp-test-subnet, count.index)}"
  ip_cidr_range = "${element(var.gcp-test-subnet-cidr, count.index)}"
  region          = "${var.gcp-region}"
  network       = "${google_compute_network.vnet-test.self_link}"
}

resource "google_compute_subnetwork" "subnet-prod" {
  count         = 2
  name          = "${element(var.gcp-prod-subnet, count.index)}"
  ip_cidr_range = "${element(var.gcp-prod-subnet-cidr, count.index)}"
  region          = "${var.gcp-region}"
  network       = "${google_compute_network.vnet-prod.self_link}"
}


###########################################################
#----------------------Virtual Networks-------------------#
###########################################################

resource "google_compute_network" "vnet-test" {
  name = "${var.gcp-test-vnet}"
  auto_create_subnetworks = false
}

resource "google_compute_network" "vnet-prod" {
  name = "${var.gcp-prod-vnet}"
  auto_create_subnetworks = false
}


###########################################################
#----------------------Virtual Machines-------------------#
###########################################################

resource "google_compute_instance" "test-database" {
  name         = "${var.gcp-test-vm}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.vnet-test.self_link}"
    subnetwork       = "${element(google_compute_subnetwork.subnet-test.*.self_link, 0)}"
  }

  metadata_startup_script = "${file("./script.sh")}"
}

resource "google_compute_instance" "prod-database" {
  name         = "${var.gcp-prod-vm}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.vnet-prod.self_link}"
    subnetwork       = "${element(google_compute_subnetwork.subnet-prod.*.self_link, 0)}"
  }

  metadata_startup_script = "${file("./script.sh")}"
}

resource "google_compute_instance" "test-client" {
  name         = "${var.gcp-test-client}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.vnet-test.self_link}"
    subnetwork       = "${element(google_compute_subnetwork.subnet-test.*.self_link, 0)}"
    access_config {}
  }

  metadata_startup_script = "${file("./script.sh")}"
}

resource "google_compute_instance" "prod-client" {
  name         = "${var.gcp-prod-client}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.vnet-prod.self_link}"
    subnetwork       = "${element(google_compute_subnetwork.subnet-prod.*.self_link, 0)}"
    access_config {}
  }

  metadata_startup_script = "${file("./script.sh")}"
}