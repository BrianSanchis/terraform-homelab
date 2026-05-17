locals {
  lb_ip   = "${var.network_prefix}.200"
  web1_ip = "${var.network_prefix}.201"
  web2_ip = "${var.network_prefix}.202"
}

# Load balancer sur pve1
resource "proxmox_virtual_environment_container" "lb" {
  description   = "Load Balancer nginx"
  node_name     = "pve1"
  vm_id         = 200
  tags          = ["lb", "terraform"]
  start_on_boot = true

  initialization {
    hostname = "lb"

    ip_config {
      ipv4 {
        address = "${local.lb_ip}/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}

# Web server 1 sur pve1
resource "proxmox_virtual_environment_container" "web1" {
  description   = "Web server 1"
  node_name     = "pve1"
  vm_id         = 201
  tags          = ["web", "terraform"]
  start_on_boot = true

  initialization {
    hostname = "web-1"

    ip_config {
      ipv4 {
        address = "${local.web1_ip}/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}

# Web server 2 sur pve2
resource "proxmox_virtual_environment_container" "web2" {
  description   = "Web server 2"
  node_name     = "pve2"
  vm_id         = 202
  tags          = ["web", "terraform"]
  start_on_boot = true

  initialization {
    hostname = "web-2"

    ip_config {
      ipv4 {
        address = "${local.web2_ip}/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}



# test1 sur pve1
resource "proxmox_virtual_environment_container" "test1" {
  description   = "test1"
  node_name     = "pve1"
  vm_id         = 203
  tags          = ["web", "terraform"]
  start_on_boot = true

  initialization {
    hostname = "test1"

    ip_config {
      ipv4 {
        address = "10.20.10.203/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}

# test2 sur pve2
resource "proxmox_virtual_environment_container" "test2" {
  description   = "test2"
  node_name     = "pve2"
  vm_id         = 204
  tags          = ["web", "terraform"]
  start_on_boot = true

  initialization {
    hostname = "test2"

    ip_config {
      ipv4 {
        address = "10.20.10.204/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}

