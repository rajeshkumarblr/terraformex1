# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE ALL THE RESOURCES TO DEPLOY AN APP IN AN AUTO SCALING GROUP WITH AN ELB
# This template runs a simple "Hello, World" web server in Auto Scaling Group (ASG) with an Elastic Load Balancer
# (ELB) in front of it to distribute traffic across the EC2 Instances in the ASG.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.15.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.15.x code.
  required_version = ">= 0.12.26"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------
variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  region = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  serverconfig = [
    for srv in var.configuration : [
      for i in range(1, srv.no_of_instances+1) : {
        instance_name = "${srv.application_name}-${i}"
        instance_type = srv.instance_type
        subnet_id   = srv.subnet_id
        ami = srv.ami
        security_groups = srv.vpc_security_group_ids
      }
    ]
  ]
}

// We need to Flatten it before using it
locals {
  instances = flatten(local.serverconfig)
}

resource "aws_instance" "web" {

  for_each = {for server in local.instances: server.instance_name =>  server}
  
  ami           = each.value.ami
  instance_type = each.value.instance_type
  #vpc_security_group_ids = each.value.security_groups
  user_data = <<EOF
#!/bin/bash
echo "Changing the hostname to ${each.value.instance_name}"
hostname ${each.value.instance_name}
echo "${each.value.instance_name}" > /etc/hostname

EOF
  #subnet_id = each.value.subnet_id
  tags = {
    Name = "${each.value.instance_name}"
  }
}


