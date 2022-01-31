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
data "aws_instance" "rancher_instance" {
  instance_id = aws_instance.rancher_server.id
}
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}
data "aws_route53_zone" "dns" {
  zone_id = "Z05090091HKD7D2WOJUY7"
}
resource "aws_instance" "rancher_server" {
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

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  vpc_security_group_ids = [module.rancher_server_sg.security_group_id]
  subnet_id              = var.subnet_id

  volume_tags = merge({"Name" = var.name}, var.tags)
  tags = merge(
  {
    "Name"              = var.name,
    "CustodianOffHours" = "off",
    "CustodianOnHours"  = "off"
  },
  var.tags)

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    module.rancher_server_sg,
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
    aws_instance.rancher_server
  ]
}

resource "null_resource" "get_rancher_kubeconfig" {
  provisioner "local-exec" {
    on_failure  = fail
    interpreter = var.null_resource_interpreter
    environment = {
      username    = var.instance_username
      name        = var.name
      host        = var.private_ip
      config_path = var.kubeconfig_path
      ssh_key     = var.ssh_key_path
    }
    command = <<EOT
      echo -e "\x1B[33mCopying rancher server kubeconfig to local machine......\x1B[0m"
      scp -o "StrictHostKeyChecking=no" -i $ssh_key $username@$host:~/k3s.yaml .
      mv k3s.yaml $config_path
      sed -i "s/127.0.0.1/$host/" $config_path
      sed -i "s/default/$name/" $config_path
    EOT
  }
  depends_on = [
    null_resource.wait_for_cloudinit
  ]
}
