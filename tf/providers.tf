provider "aws" {
  region = var.aws_region
}
provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/rke2/rke2.yaml"
  }
}
