variable "linode_api_token" {
  type = string
}

variable "root_pass" {
  type = string
}

variable "server_image" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "region" {
  type = string
  default = "us-ord"
}

variable "authorized_keys" {
  type = list
}
