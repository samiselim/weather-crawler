#!/bin/bash
set -ex

# Wait to ensure control-plane is ready
sleep 60

# Install RKE2 agent
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE=agent sh -

mkdir -p /etc/rancher/rke2

cat <<EOF > /etc/rancher/rke2/config.yaml
server: https://${control_ip}:9345
token: $(cat /var/lib/rancher/rke2/agent/token)
EOF

systemctl enable rke2-agent
systemctl start rke2-agent


sudo apt update -y
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE=agent sh -

