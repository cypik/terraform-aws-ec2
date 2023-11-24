# Terraform-aws-ec2

This README provides information about the module you have provided for provisioning AWS resources using Terraform. Please refer to the sections below for detailed information about the module.

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [Examples](#examples)
- [License](#license)

## Introduction
This Terraform module is designed to provision AWS resources using the AWS provider. It includes the creation of a Virtual Private Cloud (VPC), public subnets, IAM roles, and EC2 instances. This module facilitates infrastructure as code (IaC) for AWS environments.

## Usage
To use this module, you should have Terraform installed and configured for AWS. This module provides the necessary Terraform configuration for creating AWS resources, and you can customize the inputs as needed. Below is an example of how to use this module:

# Examples

# Example: default

```hcl
# Create EC2 instances
module "ec2" {
  source      = "git::https://github.com/cypik/terraform-aws-ec2.git?ref=v1.0.0"
  name        = "ec2"
  environment = local.environment

  # Define security group and instance details
  vpc_id            = module.vpc.id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]
  instance_count    = 1
  ami               = "ami-01dd271720c1ba44f"
  instance_type     = "t2.micro"
  public_key        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1lFi1nz4FyNSas+diEj8qji0p7rs7ewjz/OXMSQbUd7kxeX+nCNJKEC1rzOvmU67faDk3QNCsMg/DFlhz4vLb4/b4qFHGFgSaqk1WII95HAnnJECjEaQwClzgMcdQuiAxFm7ET3Em3p2cISguA5R0ynmxYDCnPbCHPiYjbgc+HPwIuqN9/pLL0moT6rPjq6yR6jrn3HuH8PTSP3A9HzStSeMCuTJDUwPpMHae4M0qxTXCQ/wvcWydOa5Hk+C8OcUfZfi7wtKyyUiG55u9RH4LzzLUqfQip1q+LkG3kH80SGsN6GZ+LKu0++xiBXWYD93mfnL51H4TdDejllt6FE/X7jf/RubFCUm0zFeB7762gMVytflmxYE/e8fwsqnnaOOgvdmLNbp0sES+qEdv9C8E8b61xbdhPMTFSd+1nuUG57KoMORsZoHGptg7i/QXs32pqlxftTqEschCpitGuBN4NxwybES6FdkYLXFZYWiv7uuujVlfxvN2mrkV3363ftc= satish@satish"

  # Networking
  subnet_ids = tolist(module.public_subnets.public_subnet_id)

  # IAM
  iam_instance_profile = module.iam-role.name

  # Root Volume
  root_block_device = [
    {
      volume_type           = "gp2"
      volume_size           = 15
      delete_on_termination = true
    }
  ]

  # EBS Volume
  ebs_volume_enabled = true
  ebs_volume_type    = "gp2"
  ebs_volume_size    = 30

  # Tags
  instance_tags = { "snapshot" = true }

  # Mount EBS With User Data
  user_data = file("user-data.sh")
}
```

This example demonstrates how to create various AWS resources using the provided modules. Adjust the input values to suit your specific requirements.

 # Example: spot_instance

```hcl
module "spot-ec2" {
  source      = "git::https://github.com/cypik/terraform-aws-ec2.git?ref=v1.0.0"
  name        = "ec2"
  environment = "test"

  ##======================================================================================
  ## Below A security group controls the traffic that is allowed to reach and leave the resources that it is associated with.
  ##======================================================================================
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_ip    = ["0.0.0.0/0"]
  ssh_allowed_ports = [22]

  #Keypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1lFi1nz4FyNSas+diEj8qji0p7rs7ewjz/OXMSQbUd7kxeX+nCNJKEC1rzOvmU67faDk3QNCsMg/DFlhz4vLb4/b4qFHGFgSaqk1WII95HAnnJECjEaQwClzgMcdQuiAxFm7ET3Em3p2cISguA5R0ynmxYDCnPbCHPiYjbgc+HPwIuqN9/pLL0moT6rPjq6yR6jrn3HuH8PTSP3A9HzStSeMCuTJDUwPpMHae4M0qxTXCQ/wvcWydOa5Hk+C8OcUfZfi7wtKyyUiG55u9RH4LzzLUqfQip1q+LkG3kH80SGsN6GZ+LKu0++xiBXWYD93mfnL51H4TdDejllt6FE/X7jf/RubFCUm0zFeB7762gMVytflmxYE/e8fwsqnnaOOgvdmLNbp0sES+qEdv9C8E8b61xbdhPMTFSd+1nuUG57KoMORsZoHGptg7i/QXs32pqlxftTqEschCpitGuBN4NxwybES6FdkYLXFZYWiv7uuujVlfxvN2mrkV3363ftc= satish@satish"

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
```
This example demonstrates how to create various AWS resources using the provided modules. Adjust the input values to suit your specific requirements.

## Module Inputs
- 'name': (string) The name of the module.
- 'environment': (string) The environment for the resources.
- 'label_order': (list) The order of labels for naming resources.
- 'availability_zones': (list) List of availability zones.
- 'vpc_id': (string) The ID of the VPC.
- 'cidr_block': (string) The CIDR block for the VPC or subnet.
- 'type': (string) The type of subnet.
- 'igw_id': (string) The ID of the Internet Gateway.
- 'ipv6_cidr_block': (string) The IPv6 CIDR block (if applicable).
- Additional inputs specific to the `spot-ec2` module.

## Module Outputs
The module may also provide output variables that can be used in other parts of your Terraform configuration. These output variables may include resource identifiers or other useful information. Refer to the module source code to identify available output variables.

## Examples
For detailed examples on how to use this module, please refer to the [Examples](https://github.com/cypik/terraform-aws-ec2/tree/master/example) directory within this repository.

## License
This Terraform module is provided under the '[License Name]' License. Please see the [LICENSE](https://github.com/cypik/terraform-aws-ec2/blob/master/LICENSE) file for more details.

## Author
Your Name
Replace '[License Name]' and '[Your Name]' with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.
