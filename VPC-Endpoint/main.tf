module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "nkp-vpc"
  cidr = var.vpc_cidr

  azs = ["ap-south-1a", "ap-south-1b"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Project = "nkp"
  }
}

resource "aws_security_group" "nkp_vpc_endpoints_sg" {
  name        = "nkp-vpc-endpoints-sg"
  description = "Allow HTTPS from VPC to endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "nkp-vpc-endpoints-sg"
    Project = "nkp"
  }
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  endpoints = {

    eks = {
      service             = "eks"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    ec2 = {
      service             = "ec2"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    ecr_api = {
      service             = "ecr.api"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    sts = {
      service             = "sts"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    ssm = {
      service             = "ssm"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

          ssmmessages = {
        service             = "ssmmessages"
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
        private_dns_enabled = true
      }

      ec2messages = {
        service             = "ec2messages"
        subnet_ids          = module.vpc.private_subnets
        security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
        private_dns_enabled = true
      }

    logs = {
      service             = "logs"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.nkp_vpc_endpoints_sg.id]
      private_dns_enabled = true
    }

    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }
  }
}

# resource "aws_launch_template" "nkp_lt" {
#   name_prefix   = "nkp-lt-"
#   image_id      = data.aws_ami.eks.id
#   instance_type = "t3.medium"

#   block_device_mappings {
#     device_name = "/dev/xvda"

#     ebs {
#       volume_size = 8
#       volume_type = "gp3"
#     }
#   }

#   metadata_options {
#     http_tokens = "required"
#   }

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name    = "nkp-node"
#       Project = "nkp"
#     }
#   }
# }

data "aws_ami" "eks" {
  most_recent = true

  owners = ["602401143452"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.18.0"

  name               = var.cluster_name
  kubernetes_version = "1.35"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  enable_irsa = true

  enabled_log_types = ["api", "audit", "authenticator"]

  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    nkp_nodes = {
      desired_size = 3
      min_size     = 3
      max_size     = 3

      instance_types = ["t3.medium"]

      # launch_template = {
      #   id      = aws_launch_template.nkp_lt.id
      #   version = "$Latest"
      # }

      subnet_ids = module.vpc.private_subnets
    }
  }

  tags = {
    Project = "nkp"
  }
}