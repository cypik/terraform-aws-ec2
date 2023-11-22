provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test-app"
  label_order = ["name", "environment"]
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

##=====================================================================
## Terraform module to create spot instance module on AWS.
##=====================================================================
module "spot-ec2" {
  source      = "./../../."
  name        = "ec2"
  environment = "test"

  ##======================================================================================
  ## Below A security group controls the traffic that is allowed to reach and leave the resources that it is associated with.
  ##======================================================================================
  vpc_id            = module.vpc.id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]

  #Keypair
  public_key = "ssh-ejllt6FE/X7jf/RubFCUm0zFeB7762gMVytflmxYE/e8fwsqnnaOOgvdmLNbp0sES+qEdv9C8E8b61xbdhPMTFSd+1nuUG57KoMORsZoHGptg7i/QXs32pqlxftTqEschCpitGuBN4NxwybES6FdkYLXFZYWiv7uuujVlfxvN2mrkV3363ftc= satish@satish"

  # Spot-instance
  spot_price                          = "0.3"
  spot_wait_for_fulfillment           = true
  spot_type                           = "persistent"
  spot_instance_interruption_behavior = "terminate"
  spot_instance_enabled               = true
  spot_instance_count                 = 1
  instance_type                       = "c4.xlarge"

  #Networking
  subnet_ids = tolist(module.public_subnets.public_subnet_id)

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
  spot_instance_tags = { "snapshot" = true }

}
