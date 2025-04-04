variable "aws_region" {
  default = "eu-west-1"
}

variable "instance_type" {
  default = "t3.medium"
}

# variable "key_name" {
#   description = "SSH key name in AWS"
# }

variable "public_key_path" {
  default = "../challenge-key.pem"
}


################################################################
########## VPC Configuration ###################################
################################################################

variable "private_subnets_config" {
  type = map(any)
}
variable "public_subnets_config" {
  type = map(any)
}
variable "vpc_cidr" {
  type        = string
  description = "Cidr Block for VPC ex: 10.0.0.0/16"
}
variable "vpc_name" {
  type        = string
  description = "Name of VPC"
}

################################################################
########## SG Configuration ###################################
################################################################
variable "sg_config" {
  type = map(any)
}


variable "control_cfg" {
  type = map(any)
}
variable "worker_cfg" {
  type = map(any)
}

# variable "control_user_data" {}
# variable "worker_user_data" {}
