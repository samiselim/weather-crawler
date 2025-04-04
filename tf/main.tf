terraform {
  backend "s3" {
    bucket = "challenge-statefile-bucket"
    key = "challenge-statefile"
    region = "eu-west-1"
  }
}
# resource "aws_key_pair" "this" {
#   key_name   = "challenge-key"
#   public_key = file(var.public_key_path)
# }

module "vpc" {
  source                 = "./modules/VPC"
  vpc_cidr               = var.vpc_cidr
  public_subnets_config  = var.public_subnets_config
  private_subnets_config = var.private_subnets_config
  vpc_name               = var.vpc_name
} 

module "sg" {
  source = "./modules/SG"
  sg_config = var.sg_config
  sg_name = "sg"
  vpc_id = module.vpc.vpc_id
}

module "control" {
  source = "./modules/EC2"
  ec2_config = var.control_cfg
  ec2_subnet_id = module.vpc.public_subnet_ids[0]
  vpc_id = module.vpc.vpc_id
  sg = module.sg.sg_id
#   ami = data.aws_ami.aws_image_latest.id
  ami = "ami-0f0c3baa60262d5b9"
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y 
                sudo apt install -y curl tar
                curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE=server sh -
                sudo systemctl enable rke2-server
                sudo systemctl start rke2-server

                curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            EOF
}
module "worker" {
  source = "./modules/EC2"
  ec2_config = var.worker_cfg
  ec2_subnet_id = module.vpc.public_subnet_ids[0]
  vpc_id = module.vpc.vpc_id
  sg = module.sg.sg_id
#   ami = data.aws_ami.aws_image_latest.id
  ami = "ami-0f0c3baa60262d5b9"
  user_data = <<-EOF
              #!/bin/bash
              sleep 60

              # Install RKE2 Agent
              curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -

              mkdir -p /etc/rancher/rke2

              cat <<EOT > /etc/rancher/rke2/config.yaml
              server: https://${data.aws_instances.control.private_ips[0]}:9345
              token: ""
              EOT

              systemctl enable rke2-agent
              systemctl start rke2-agent
            EOF
}
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }
  timeout = 600
}
resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true

  set {
    name  = "hostname"
    value = "rancher.localhost" # Replace with your actual domain or leave like this for now
  }

  set {
    name  = "replicas"
    value = "1"
  }

  # depends_on = [helm_release.cert_manager]
}