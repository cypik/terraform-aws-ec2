provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test-app"
  label_order = ["name", "environment"]
}

module "vpc" {
  source      = "cypik/vpc/aws"
  version     = "1.0.3"
  name        = "app"
  environment = local.environment
  label_order = local.label_order
  cidr_block  = "172.16.0.0/16"
}


module "public_subnets" {
  source             = "cypik/subnet/aws"
  version            = "1.0.5"
  name               = "public-subnet"
  environment        = local.environment
  label_order        = local.label_order
  availability_zones = ["eu-west-1b", "eu-west-1c"]
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}


module "spot-ec2" {
  source      = "./../../."
  name        = "ec2"
  environment = "test"

  vpc_id            = module.vpc.vpc_id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]

  ###allow ingress port and ip
  allow_ingress_port_ip = {
    "80"  = "0.0.0.0/0"
    "443" = "0.0.0.0/0"
  }

  #Keypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXtnrTCvN0ThcuIARFyEyQUSP9W7JUKs92R7ccjf9D4ccOYV6DMAtezwp48DplX+4Thap3v8tiFvwbtkT1Bld7WHLxD9lKsEkuuJBuCc9vpseClV9O+bN1Gx0SKiV+1AkmvsTckhyO55ldnkeGh7L+LNsaAsC5BbmhwLqlLnSHj8RdRu8z0GNIRmqRit0tNXXfux0VP0hdXAh+IblsQzqbEWr7viG2oWcntQlSZgVf+kS8SisbnsrM0b56rOVG5MZBH98cVjuazt0NHxDodrCYdZVc6dS4pHc+WxunaILSXyAJJHOEaSwU2rwCD03HPjLZD6WcU5Jlo+vz5ofIc3Vz06MgYRkFJHB1cRgqpdF5ckTPSa7KjjiK9yDJmxwiw7ZNRrs525oqk5uJfXkHmOcIvfeRhnLBg84Eqvqdu5jjsIJRSiOCZdUpB82KZ5DaPhQH0Ev6ua9JoMQCkUCUiQlNvHqjhz+Iy4fn3lsvengN7ennSRjPdvhhDRRDRjH+gVk= satish@satish"

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
