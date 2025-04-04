# output "control_plane_ip" {
#   value = module.control.public_ec2_ips
# }

# output "worker_ip" {
#   value = module.worker.public_ec2_ips
# }

output "first_control_ip" {
  value = data.aws_instances.control.private_ips[0]
}
