provider "aws" {
  region = var.aws_region
}
provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/rke2/rke2.yaml"
  }
}
provider "kubernetes" {
  config_path = "/etc/rancher/rke2/rke2.yaml"
}
# terraform {
#   required_providers {
#     kubectl = {
#       source  = "alekc/kubectl"
#       version = ">= 2.0.2"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "2.5.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "2.0.1"
#     }
#   }
# }