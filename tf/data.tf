# data "aws_ami" "aws_image_latest" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-kernel-5.10-hvm-2.0.20240131.0-x86_64-gp2"]
#   }
# }


data "aws_instances" "control" {
  filter {
    name   = "tag:Name"
    values = ["rke2-control-plane"]
  }
}

