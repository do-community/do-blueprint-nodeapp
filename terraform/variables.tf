variable "do_token" {
  description = "Read/Write DigitalOcean API key to manage resources"
}

variable "ssh_keys" {
  type        = "list"
  description = "SSH keys to add to the Droplet"
}
