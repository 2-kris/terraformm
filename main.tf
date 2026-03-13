provider "aws" {
  region = "ap-south-1"
}

module "ec2" {
  source            = "./modules/ec2_instance"
  aws_ami           = "ami-019715e0d74f695be"
  aws_instance_type = "t2.micro"
}