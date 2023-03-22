variable "namespace" {
    description = "The project namespace"
    type = string
}

variable "ssh_key_pair" {
    description = "Auth ssh key"
    default = null
    type = string
}

variable "region" {
    description = "Deploy region"
    default = "us-east-1"
    type = string
}
