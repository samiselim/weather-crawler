# ---------------------------------------------
# Step 1: RKE2 Kubernetes Cluster using Terraform
# ---------------------------------------------
# Structure:
# - VPC and Subnet
# - Security Group
# - EC2 Instances (1 master, 1 worker)
# - RKE2 server on master, agent on worker
terraform {
  backend "s3" {
    bucket = "challenge-statefile-bucket"
    key = "challenge-statefile"
    region = "eu-west-1"
  }
}
# ------------ providers.tf ------------
provider "aws" {
  region = "eu-west-1" # change as needed
}
provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/rke2/rke2.yaml"
  }
}
provider "kubernetes" {
  config_path = "/etc/rancher/rke2/rke2.yaml"
}

# ------------ variables.tf ------------
variable "key_name" {}
variable "vpc_id" {}
variable "subnet_id" {}

# ------------ security.tf ------------
resource "aws_security_group" "rke2" {
  name        = "rke2-sg"
  description = "Allow SSH, RKE2 traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------ master.tf ------------
resource "aws_instance" "master" {
  ami                    = "ami-0df368112825f8d8f" # Ubuntu 22.04 in us-east-1
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.rke2.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # Install RKE2 Server
              curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
              systemctl enable rke2-server.service
              systemctl start rke2-server.service

              # Wait for rke2.yaml to be created
              while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do sleep 5; done

              # Link kubectl from RKE2
              ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl

              # Export KUBECONFIG
              echo "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml" >> /etc/profile
              export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

              # Install AWS CLI
              apt update -y
              apt install -y awscli
              EOF

  tags = {
    Name = "rke2-master"
  }
}

# ------------ worker.tf ------------
# data "aws_instance" "master" {
#   filter {
#     name   = "tag:Name"
#     values = ["rke2-master"]
#   }
# }

resource "aws_instance" "worker" {
  ami                    = "ami-0df368112825f8d8f"
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.rke2.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt update -y && apt install -y curl
              curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -
              mkdir -p /etc/rancher/rke2
              echo "server: https://${aws_instance.master.private_ip}:9345" > /etc/rancher/rke2/config.yaml
              echo "token: $(cat /var/lib/rancher/rke2/server/node-token)" >> /etc/rancher/rke2/config.yaml
              systemctl enable rke2-agent.service
              systemctl start rke2-agent.service
              EOF

  tags = {
    Name = "rke2-worker"
  }
}

# ------------ outputs.tf ------------
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

# ------------ cert-manager + rancher.tf ------------
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
   set {
    name  = "startupapicheck.enabled"
    value = "false"
  }
  timeout = 600
}

resource "null_resource" "wait_for_cert_manager" {
  provisioner "local-exec" {
    command = "echo 'Waiting for cert-manager to initialize...'; sleep 60"
  }
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true

  set {
    name  = "hostname"
    value = "rancher.localhost"
  }

  set {
    name  = "replicas"
    value = "1"
  }

  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }
  wait    = true
  timeout = 600

  depends_on = [null_resource.wait_for_cert_manager]
} 

resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mongodb"
  version    = "16.4.12" 
  namespace  = "mongodb"
  create_namespace = true

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  timeout = 600
}

resource "helm_release" "airflow" {
  name             = "airflow"
  repository       = "https://airflow.apache.org"
  chart            = "airflow"
  namespace        = "airflow"
  create_namespace = true

  set {
    name  = "executor"
    value = "LocalExecutor"
  }

  set {
    name  = "webserver.defaultUser.username"
    value = "admin"
  }

  set {
    name  = "webserver.defaultUser.password"
    value = "admin"
  }

  set {
    name  = "webserver.service.type"
    value = "NodePort"
  }

  set {
    name  = "webserver.service.nodePort.http"
    value = "30808"
  }
}