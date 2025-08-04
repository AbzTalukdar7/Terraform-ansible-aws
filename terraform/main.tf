terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  required_version = ">= 1.2"
}

data "template_file" "userdata" {
  template = file("${path.module}/../ansible/user_data.yml")
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_role" "ec2_s3_role"{
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# CREATE SECURITY GROUP THAT IS APPLIED TO THE INSTANCE
#
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-generated-key-${random_id.suffix.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_sensitive_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/my_terraform_key"
  file_permission = "0600"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = ["allow_ssh"]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name      = aws_key_pair.generated_key.key_name
  user_data = data.template_file.userdata.rendered
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_instance_profile.name

  tags = {
    Name = "TerraformAnsibleEC2"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("${aws_key_pair.generated_key.key_name}")}"
    timeout = "2m"
    agent = false
  }
}

resource "aws_s3_bucket" "deploy_bucket" {
  bucket = "abz-devops-project-1702"
  force_destroy = true
}

resource "aws_s3_object" "app_zip" {
  bucket = aws_s3_bucket.deploy_bucket.id
  key    = "app.zip"
  source = "../packaged/app.zip"
  etag   = filemd5("../packaged/app.zip")
}

resource "aws_s3_object" "ansible_zip" {
  bucket = aws_s3_bucket.deploy_bucket.id
  key    = "ansible.zip"
  source = "../packaged/ansible.zip"
  etag   = filemd5("../packaged/ansible.zip")
}

output "private_key_pem" {
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
  description = "Private key content to save as PEM file for SSH and Ansible"
}

output "aws_instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the created EC2 instance"
}

