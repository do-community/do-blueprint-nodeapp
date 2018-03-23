provider "digitalocean" {
  token = "${var.do_token}"
}

# Create new tags
resource "digitalocean_tag" "bp" {
  name = "bp"
}

resource "digitalocean_tag" "bp-nodeapp" {
  name = "bp-nodeapp"
}

resource "digitalocean_tag" "bp-nodeapp-nodejs" {
  name = "bp-nodeapp-nodejs"
}

resource "digitalocean_tag" "bp-nodeapp-mongo" {
  name = "bp-nodeapp-mongo"
}


#Create droplet for node and nginx
resource "digitalocean_droplet" "nodejs" {
  count     = "1"
  name      = "nodejs-${count.index + 1}"
  image     = "ubuntu-16-04-x64"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  monitoring = true
  tags   = ["bp", "bp-nodeapp", "bp-nodeapp-nodejs"]
  ssh_keys  = ["${var.ssh_keys}"]
  user_data = "${file("${path.module}/files/userdata")}"
}

# create block storage volume for mongo data files 
resource "digitalocean_volume" "dbvolume" {
  count = "1"
  region = "sfo2"
  name = "dbvolume-${count.index+1}"
  size = "100"
  description = "Data volume for mongoDB"
}

# create droplet for mongodb
resource "digitalocean_droplet" "mongodb" {
  count     = "1"
  name      = "mongodb-${count.index + 1}"
  image     = "ubuntu-16-04-x64"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  monitoring = true
  tags   = ["bp", "bp-nodeapp", "bp-nodeapp-mongo"]
  private_networking = true
  ssh_keys  = ["${var.ssh_keys}"]
  user_data = "${file("${path.module}/files/userdata")}"
  volume_ids = ["${digitalocean_volume.dbvolume.*.id[count.index]}"]
}

# ansible host definitions

resource "ansible_host" "ansible_nodejs" {
  count              = "1"
  inventory_hostname = "${digitalocean_droplet.nodejs.*.name[count.index]}"
  groups             = ["nodejs"]

  vars {
    ansible_host = "${digitalocean_droplet.nodejs.*.ipv4_address[count.index]}"
  }
}

resource "ansible_host" "ansible_mongodb" {
  count              = "1"
  inventory_hostname = "${digitalocean_droplet.mongodb.*.name[count.index]}"
  groups             = ["mongodb"]

  vars {
    ansible_host = "${digitalocean_droplet.mongodb.*.ipv4_address[count.index]}"
  }
}


# create cloud firewalls to protect node and mongo servers

resource "digitalocean_firewall" "web" {
  name = "bp-nodeapp-web"

  droplet_ids = ["${digitalocean_droplet.nodejs.*.id}"]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "80"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol           = "tcp"
      port_range         = "443"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule = [
    {
      protocol                = "tcp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "udp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "ssh" {
  name = "bp-nodeapp-ssh"

  droplet_ids = [ 
    "${digitalocean_droplet.nodejs.*.id}",
    "${digitalocean_droplet.mongodb.*.id}",
  ]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "22"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule = [
    {
      protocol                = "tcp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "udp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "nodeapp" {
  name = "bp-nodeapp-app"

  droplet_ids = ["${digitalocean_droplet.nodejs.*.id}"]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "8080"
      source_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule = [
    {
      protocol                = "tcp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "udp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "mongodb" {
  name = "bp-nodeapp-mongodb"

  droplet_ids = ["${digitalocean_droplet.mongodb.*.id}"]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "27017-27019"
      source_tags        = ["bp-nodeapp-nodejs"]
    },
  ]

  outbound_rule = [
    {
      protocol                = "tcp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol                = "udp"
      port_range              = "1-65535"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
    },
  ]
}


