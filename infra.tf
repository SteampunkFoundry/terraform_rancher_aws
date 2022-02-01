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
data "aws_instance" "rancher_instance" {
  instance_id = aws_instance.rancher_server.id
}
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}
data "aws_route53_zone" "dns" {
  zone_id = "Z094996227DIM7LY3S4VY"
}

resource "tls_private_key" "rancher_ssh_key" {
  algorithm = "RSA"
  rsa_bits = "4096"
}

resource "aws_secretsmanager_secret" "rancher_ssh_key" {
  name = "webmod-rancher-ssh"
  description = "Rancher server ssh key"
  recovery_window_in_days = 0
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rancher_ssh_contents" {
  secret_id = aws_secretsmanager_secret.rancher_ssh_key.id
  secret_string = <<EOF
   {
    "rancher_ssh.pem": "${tls_private_key.rancher_ssh_key.private_key_pem}"
   }
  EOF
}

resource "aws_key_pair" "rancher_key" {
  key_name = "${var.name}-rancher"
  public_key = tls_private_key.rancher_ssh_key.public_key_openssh
  tags = var.tags
}
resource "aws_instance" "rancher_server" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = var.instance_type
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
  subnet_id              = element(data.terraform_remote_state.vpc.outputs.private_subnets, 0)

  volume_tags = merge({"Name" = "${var.name}-rancher-server"}, var.tags)
  tags = merge(
  {
    "Name"              = "${var.name}-rancher-server",
    "CustodianOffHours" = "off",
    "CustodianOnHours"  = "off"
  },
  var.tags)

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    module.rancher_server_sg,
    data.terraform_remote_state.vpc
  ]
}

module "rancher_server_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.7.0"
  create  = true

  use_name_prefix = true
  name            = "${var.name}-rancher-server-sg"
  description     = "Security group for the Rancher Server EC2 instance"
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id

  egress_rules              = ["all-all"]
  ingress_cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  ingress_rules             = ["ssh-tcp", "https-443-tcp", "kubernetes-api-tcp"]
  ingress_with_cidr_blocks  = [
    {
      from_port   = 8
      to_port     = 0
      protocol    = "icmp"
      description = "Allow ping from within VPC"
      cidr_blocks = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
    }
  ]

  tags = var.tags

  depends_on = [
    data.terraform_remote_state.vpc
  ]
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
      host = aws_instance.rancher_server.private_ip
      user = var.instance_username
      private_key = tls_private_key.rancher_ssh_key.private_key_pem
    }
  }
  depends_on = [
    aws_instance.rancher_server
  ]
}

resource "local_file" "rancher_ssh" {
  sensitive_content = tls_private_key.rancher_ssh_key.private_key_pem
  filename          = var.ssh_key_path
  file_permission   = "644"
}

resource "null_resource" "get_rancher_kubeconfig" {
  provisioner "local-exec" {
    on_failure  = fail
    interpreter = var.null_resource_interpreter
    environment = {
      username    = var.instance_username
      name        = var.name
      host        = aws_instance.rancher_server.private_ip
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

resource "aws_route53_record" "rancher_endpoint" {
  name    = var.rancher_server_dns
  type    = "A"
  ttl     = "300"
  zone_id = data.aws_route53_zone.dns.zone_id
  records = [aws_instance.rancher_server.private_ip]
}
