#ssh key pair
resource "tls_private_key" "key-pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "ssh-key" {
  key_name   = var.key_name
  public_key = tls_private_key.key-pair.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.ssh-key.key_name
  security_groups = [aws_security_group.ec2_sg.id]
  subnet_id       = aws_subnet.public_subnet[0].id
  user_data       = <<-EOF
    #!/bin/bash
    sudo su
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install nginx -y
    sudo systemctl stop nginx
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    npm install -g pm2
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
    tar xvf node_exporter-1.7.0.linux-amd64.tar.gz
    cd node_exporter-1.7.0.linux-amd64


  EOF
  tags = {
    Name = "kox"
  }
}

#security group
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3500
    to_port     = 3500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #don't allow all ip address to ssh in prod
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #don't allow all ip address to ssh in prod
  }
  tags = {
    Name = "sr-security_group"
  }
}

# Observability Instance
# resource "aws_instance" "Observability_instance" {
#   ami             = data.aws_ami.ubuntu.id
#   instance_type   = var.instance_type
#   key_name        = aws_key_pair.ssh-key.key_name
#   security_groups = [aws_security_group.obs_sg.id]
#   subnet_id       = aws_subnet.public_subnet[0].id
#   user_data = <<-EOF
#     sudo apt update -y
#     sudo apt install wget tar -y
#     wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz
#     tar xvf prometheus-2.52.0.linux-amd64.tar.gz
#     sudo apt-get install -y apt-transport-https software-properties-common wget
#     wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
#     echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
#     sudo add-apt-repository "deb https://apt.grafana.com stable main"
#     sudo apt install grafana -y
#     sudo systemctl enable grafana-server
#     sudo systemctl start grafana-server
#   EOF
#   associate_public_ip_address = true
#   tags = {
#     Name = "observability_instance"
#   }
# }

# #security group
# resource "aws_security_group" "obs_sg" {
#   vpc_id = aws_vpc.main.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] #don't allow all ip address to ssh in prod
#   }

#   ingress {
#     from_port   = 9090
#     to_port     = 9090
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "obs-security_group"
#   }
# }
