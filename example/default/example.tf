##==================================================================
## Provider block added, Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
##====================================================================

provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "app"
  label_order = ["name", "environment"]
}

##======================================================================================
## A VPC is a virtual network that closely resembles a traditional network that you'd operate in your own data center.
##=====================================================================================
module "vpc" {
  source      = "git::https://github.com/opz0/terraform-aws-vpc.git?ref=v1.0.0"
  name        = "app"
  environment = local.environment
  label_order = local.label_order
  cidr_block  = "172.16.0.0/16"
}

##=======================================================================
## A subnet is a range of IP addresses in your VPC.
##========================================================================
module "public_subnets" {
  source             = "git::https://github.com/opz0/terraform-aws-subnet.git?ref=v1.0.0"
  name               = "public-subnet"
  environment        = local.environment
  label_order        = local.label_order
  availability_zones = ["eu-west-1b", "eu-west-1c"]
  vpc_id             = module.vpc.id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "iam-role" {
  source             = "git::https://github.com/opz0/terraform-aws-iam-role.git?ref=v1.0.0"
  name               = "iam-role"
  environment        = local.environment
  label_order        = local.label_order
  assume_role_policy = data.aws_iam_policy_document.default.json
  policy_enabled     = true
  policy             = data.aws_iam_policy_document.iam-policy.json
}

data "aws_iam_policy_document" "default" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iam-policy" {
  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
    "ssmmessages:OpenDataChannel"]
    effect    = "Allow"
    resources = ["*"]
  }
}

##=====================================================================================
## Terraform module to create ec2 instance module on AWS.
##=====================================================================================
module "ec2" {
  source            = "./../../."
  name              = "ec2"
  environment       = local.environment
  vpc_id            = module.vpc.id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]
  #Instance
  instance_count = 1
  ami            = "ami-01dd271720c1ba44f"
  instance_type  = "t2.micro"

  #Keypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1lFi1nz4FyNSas+diEj8qji0p7rs7ewjz/OXMSQbUd7kxeX+nCNJKEC1rzOvmU67faDk3QNCsMg/DFlhz4vLb4/b4qFHGFgSaqk1WII95HAnnJECjEaQwClzgMcdQuiAxFm7ET3Em3p2cISguA5R0ynmxYDCnPbCHPiYjbgc+HPwIuqN9/pLL0moT6rPjq6yR6jrn3HuH8PTSP3A9HzStSeMCuTJDUwPpMHae4M0qxTXCQ/wvcWydOa5Hk+C8OcUfZfi7wtKyyUiG55u9RH4LzzLUqfQip1q+LkG3kH80SGsN6GZ+LKu0++xiBXWYD93mfnL51H4TdDejllt6FE/X7jf/RubFCUm0zFeB7762gMVytflmxYE/e8fwsqnnaOOgvdmLNbp0sES+qEdv9C8E8b61xbdhPMTFSd+1nuUG57KoMORsZoHGptg7i/QXs32pqlxftTqEschCpitGuBN4NxwybES6FdkYLXFZYWiv7uuujVlfxvN2mrkV3363ftc= satish@satish"

  #Networking
  subnet_ids = tolist(module.public_subnets.public_subnet_id)

  #IAM
  iam_instance_profile = module.iam-role.name

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp2"
      volume_size           = 15
      delete_on_termination = true
    }
  ]

  #EBS Volume
  ebs_volume_enabled = true
  ebs_volume_type    = "gp2"
  ebs_volume_size    = 30

  #Tags
  instance_tags = { "snapshot" = true }

  #Mount EBS With User Data
  user_data = file("user-data.sh")
}
