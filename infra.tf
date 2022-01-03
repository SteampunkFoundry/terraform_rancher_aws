data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"] // Canonical Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "description"
    values = ["*20.04 LTS*"]
  }
}
data "aws_vpc" "eks-rancher" {
  id = var.vpc_id
}
data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  tags = {
    Network = "Private"
  }
}

module "rancher_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.3.0"

  name                   = var.name
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = var.instance_type
  private_ip             = var.private_ip
  key_name               = var.key_name
  user_data              = templatefile("${path.module}/templates/userdata.tmpl",
    {
      docker_version = var.docker_version
      k3s_version    = var.k3s_version
      username       = var.instance_username
    }
  )

  vpc_security_group_ids = [module.rancher_server_sg.security_group_id]
  subnet_id              = var.subnet_id

  tags = var.tags

  depends_on = [
    module.rancher_server_sg,
#    module.rds
  ]
}

module "rancher_server_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.7.0"
  create  = true

  use_name_prefix = true
  name            = "${var.name}-sg"
  description     = "Security group for the Rancher Server EC2 instance"
  vpc_id          = data.aws_vpc.eks-rancher.id

  egress_rules              = ["all-all"]
  ingress_cidr_blocks       = [data.aws_vpc.eks-rancher.cidr_block]
  ingress_rules             = ["ssh-tcp", "https-443-tcp", "kubernetes-api-tcp"]
  ingress_with_cidr_blocks  = [
    {
      from_port   = 8
      to_port     = 0
      protocol    = "icmp"
      description = "Allow ping from within VPC"
      cidr_blocks = data.aws_vpc.eks-rancher.cidr_block
    }
  ]

  tags = var.tags
}

resource "null_resource" "wait_for_cloudinit" {
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for user data script to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'cloud-init has completed...'",
    ]
    connection {
      type = "ssh"
      host = var.private_ip
      user = var.instance_username
      private_key = file(var.ssh_key_path)
    }
  }
  depends_on = [
    module.rancher_server
  ]
}

resource "null_resource" "get_rancher_kubeconfig" {
  provisioner "local-exec" {
    on_failure  = fail
    interpreter = var.null_resource_interpreter
    environment = {
      username    = var.instance_username
      host        = var.private_ip
      config_path = var.kubeconfig_path
      ssh_key     = var.ssh_key_path
    }
    command = <<EOT
      echo -e "\x1B[33mCopying rancher server kubeconfig to local machine......\x1B[0m"
      scp -o "StrictHostKeyChecking=no" -i $ssh_key $username@$host:~/k3s.yaml .
      mv k3s.yaml $config_path
      sed -i "s/127.0.0.1/$host/" $config_path
    EOT
  }
  depends_on = [
    null_resource.wait_for_cloudinit
  ]
}
### IN PROGRESS ###
#
# RDS module is for configuring a highly available k3s cluster. https://rancher.com/docs/rancher/v2.6/en/installation/resources/k8s-tutorials/infrastructure-tutorials/rds/
#
#module "rds" {
#  source  = "terraform-aws-modules/rds/aws"
#  version = "3.4.1"
#
#  identifier           = "${var.name}-dev"
#  engine               = "mysql"
#  engine_version       = "5.7.34"
#  family               = "mysql5.7" # DB parameter group
#  major_engine_version = "5.7"      # DB option group
#  instance_class       = var.db_instance_type
#  allocated_storage     = var.db_storage
#
#  name     = var.db_name
#  username = "admin"
#  password = var.db_password
#  port     = 3306
#
#  subnet_ids             = data.aws_subnet_ids.private.ids
#  vpc_security_group_ids = [module.rds_sg.security_group_id]
#
#  maintenance_window              = "Mon:00:00-Mon:03:00"
#  backup_window                   = "03:00-06:00"
#  backup_retention_period = 7
#  skip_final_snapshot     = true
#
#  tags = var.tags
#
#  depends_on = [
#    module.rancher_server_sg
#  ]
#}
#
#module "rds_sg" {
#  source  = "terraform-aws-modules/security-group/aws"
#  version = "~> 4.0"
#  create  = true
#
#  use_name_prefix = true
#  name            = "${var.name}-sg"
#  description     = "Security group for the Rancher EC2 instance"
#  vpc_id          = data.aws_vpc.eks-rancher.id
#
#  egress_rules              = ["all-all"]
#  computed_ingress_with_source_security_group_id = [
#    {
#      rule                     = "mysql-tcp"
#      description              = "Access for Rancher server"
#      source_security_group_id = module.rancher_server_sg.security_group_id
#    },
#  ]
#  number_of_computed_ingress_with_source_security_group_id = 1
#
#  tags = var.tags
#  depends_on = [
#    module.rancher_server_sg
#  ]
#}
