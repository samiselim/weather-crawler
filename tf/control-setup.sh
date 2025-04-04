#!/bin/bash
set -ex
# Install RKE2
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
systemctl enable rke2-server
systemctl start rke2-server



sudo apt update -y 
sudo apt install -y curl tar
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE=server sh -
sudo systemctl enable rke2-server
sudo systemctl start rke2-server

curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl