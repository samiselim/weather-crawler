vpc_name = "challenge"
vpc_cidr     = "10.0.0.0/16"
public_subnets_config = {
  subnet_count = [1]
  subnet_cidrs = ["10.0.1.0/24"]
  subnet_azs   = ["eu-west-1a"]
}
private_subnets_config = {
  subnet_count = [0]
#   subnet_cidrs = ["10.0.3.0/24" , "10.0.4.0/24"]
#   subnet_azs   = ["eu-west-3a" , "eu-west-3b"]
}

sg_config = {
  ingress_count = [{count = 1}]
  ingress_rule = [{
    fromport = 0
    toport = 65535
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  }]
}

control_cfg = {
  instance_count = [1]
  instance_type = ["t3.medium"]
  key_name = ["challenge-key"]
  instance_name = ["rke2-control-plane"]
}

worker_cfg = {
  instance_count = [1]
  instance_type = ["t3.medium"]
  key_name = ["challenge-key"]
  instance_name = ["rke2-worker"]
}
