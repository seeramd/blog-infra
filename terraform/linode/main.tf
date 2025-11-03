terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "3.0.0"
    }
  }
}

provider "linode" {
  token = var.linode_api_token
}

resource "linode_vpc" "vpc" {
    label = "web-vpc"
    region = var.region
}

resource "linode_vpc_subnet" "vpcsubnet" {
    vpc_id = linode_vpc.vpc.id
    label = "primary-subnet"
    ipv4 = "10.0.1.0/24"
}

resource "linode_instance" "websrv" {
  label           = "websrv01"
  image           = var.server_image
  region          = var.region
  type            = var.instance_type
  authorized_keys = var.authorized_keys
  root_pass       = var.root_pass

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.vpcsubnet.id
    ipv4 {
      vpc = "10.0.1.20"
    }
  }
  tags = ["webserver"]
  swap_size  = 256
  private_ip = true
}

resource "linode_instance" "dbsrv" {
  label           = "dbsrv01"
  image           = var.server_image
  region          = var.region
  type            = var.instance_type
  authorized_keys = var.authorized_keys
  root_pass       = var.root_pass

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vpc"
    subnet_id = linode_vpc_subnet.vpcsubnet.id
    ipv4 {
      vpc = "10.0.1.30"
    }
  }
  tags = ["db"]
  swap_size  = 256
  private_ip = true
}

resource "linode_firewall" "webfirewall" {
  label = "web-firewall"

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-ssh-alt"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "2222"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound_policy = "DROP"

  outbound {
    label    = "reject-http"
    action   = "DROP"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound {
    label    = "reject-https"
    action   = "DROP"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound_policy = "ACCEPT"

  linodes = [linode_instance.websrv.id]
}

resource "linode_firewall" "dbfirewall" {
  label = "db-firewall"

  inbound {
    label    = "allow-postgres"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "5432"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-ssh-alt"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "2222"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound_policy = "DROP"

  outbound_policy = "ACCEPT"

  linodes = [linode_instance.dbsrv.id]
}
