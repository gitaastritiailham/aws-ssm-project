provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "plab_vpc" {
  cidr_block           = "10.11.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "plab_vpc"
  }
}

# Subnets
resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.plab_vpc.id
  cidr_block              = "10.11.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "plab_pub_a"
  }
}

resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.plab_vpc.id
  cidr_block              = "10.11.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "plab_pub_b"
  }
}

resource "aws_subnet" "pri_a" {
  vpc_id            = aws_vpc.plab_vpc.id
  cidr_block        = "10.11.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "plab_pri_a"
  }
}

resource "aws_subnet" "pri_b" {
  vpc_id            = aws_vpc.plab_vpc.id
  cidr_block        = "10.11.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "plab_pri_b"
  }
}

resource "aws_subnet" "pri_rds" {
  vpc_id            = aws_vpc.plab_vpc.id
  cidr_block        = "10.11.5.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "plab_pri_rds"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.plab_vpc.id

  tags = {
    Name = "plab_igw"
  }
}

# Elastic IP
resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.class_no}_eip_a"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "${var.class_no}_eip_b"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "natgw_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.pub_a.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.class_no}_natgw_a"
  }
}

resource "aws_nat_gateway" "natgw_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.pub_b.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.class_no}_natgw_b"
  }
}

# Route Tables
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.plab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.class_no}_pub_rt"
  }
}

resource "aws_route_table" "pri_rt_a" {
  vpc_id = aws_vpc.plab_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_a.id
  }

  tags = {
    Name = "${var.class_no}_pri_rt_a"
  }
}

resource "aws_route_table" "pri_rt_b" {
  vpc_id = aws_vpc.plab_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_b.id
  }

  tags = {
    Name = "${var.class_no}_pri_rt_b"
  }
}

resource "aws_route_table" "rds_rt" {
  vpc_id = aws_vpc.plab_vpc.id

  tags = {
    Name = "${var.class_no}_rds_rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pri_a" {
  subnet_id      = aws_subnet.pri_a.id
  route_table_id = aws_route_table.pri_rt_a.id
}

resource "aws_route_table_association" "pri_b" {
  subnet_id      = aws_subnet.pri_b.id
  route_table_id = aws_route_table.pri_rt_b.id
}

resource "aws_route_table_association" "pri_rds" {
  subnet_id      = aws_subnet.pri_rds.id
  route_table_id = aws_route_table.rds_rt.id
}

# Security Group Bastion
# resource "aws_security_group" "bssg" {
#   name        = "${var.class_no}_plab_bssg"
#   description = "security group for plab bastion"
#   vpc_id      = aws_vpc.plab_vpc.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# IAM Role for AWS Systems Manager
resource "aws_iam_role" "ssm_role" {
  name = "${var.class_no}_plab_ssm_role"

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

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.class_no}_plab_ssm_profile"
  role = aws_iam_role.ssm_role.name
}

# Security Group Web Server
resource "aws_security_group" "websvsg" {
  name        = "${var.class_no}_plab_websvsg"
  description = "security group for plab web server"
  vpc_id      = aws_vpc.plab_vpc.id

  # ingress {
  #   from_port       = 22
  #   to_port         = 22
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.bssg.id]
  # }

# Security Group Web Server (Hanya Port 80 dari ALB)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elbsg.id]
  }

# Penting: SSM membutuhkan akses keluar (egress) ke internet/endpoint SSM via NAT GW
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group RDS
resource "aws_security_group" "rdssg" {
  name        = "${var.class_no}_plab_rdssg"
  description = "security group for plab rds"
  vpc_id      = aws_vpc.plab_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.websvsg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group ELB
resource "aws_security_group" "elbsg" {
  name        = "${var.class_no}_plab_elbsg"
  description = "security group for plab elb"
  vpc_id      = aws_vpc.plab_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Bastion Server
# resource "aws_instance" "bastion" {
#   ami                         = "ami-0c101f26f147fa7fd"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.pub_a.id
#   key_name                    = var.key_name
#   vpc_security_group_ids      = [aws_security_group.bssg.id]
#   associate_public_ip_address = true

#   tags = {
#     Name = "plab_bastion"
#   }
# }


# EC2 Instances (Menggunakan IAM Instance Profile)

# Web Server A
resource "aws_instance" "websv_a" {
  ami                  = "ami-0c101f26f147fa7fd"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.pri_a.id

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.websvsg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd php php-fpm php-mysqli php-json php-devel
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              systemctl enable httpd
              systemctl start httpd
              echo "<?php print '<h1>Hello SV1A</h1>'; ?>" > /var/www/html/hello.php
              EOF

  tags = {
    Name = "plab_websv_a"
  }
   depends_on = [
    aws_iam_role_policy_attachment.ssm_attach
  ]
}

# AMI
resource "aws_ami_from_instance" "web_ami" {
  name               = "plab_websv_ami"
  source_instance_id = aws_instance.websv_a.id

  depends_on = [
    aws_instance.websv_a
  ]
}

# Web Server B
resource "aws_instance" "websv_b" {
  ami                  = aws_ami_from_instance.web_ami.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.pri_b.id

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.websvsg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              sleep 30
              echo "<?php print '<h1>Hello SV1B</h1>'; ?>" > /var/www/html/hello.php
              EOF

  tags = {
    Name = "plab_websv_b"
  }
  depends_on = [
    aws_iam_role_policy_attachment.ssm_attach
  ]
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "plab-elb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.plab_vpc.id

  health_check {
    path = "/hello.php"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.class_no}-plab-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elbsg.id]

  subnets = [
    aws_subnet.pub_a.id,
    aws_subnet.pub_b.id
  ]
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Target Attachments
resource "aws_lb_target_group_attachment" "websv_a" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.websv_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "websv_b" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.websv_b.id
  port             = 80
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subg" {
  name = "plab_rds_subg"

  subnet_ids = [
    aws_subnet.pri_a.id,
    aws_subnet.pri_b.id,
    aws_subnet.pri_rds.id
  ]

  tags = {
    Name = "plab_rds_subg"
  }
}

# RDS
resource "aws_db_instance" "rds" {
  identifier             = "plab-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"

  username = "root"
  password = var.db_password

  db_name = "${var.class_no}_db"

  db_subnet_group_name   = aws_db_subnet_group.rds_subg.name
  vpc_security_group_ids = [aws_security_group.rdssg.id]

  availability_zone = "us-east-1c"

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "plab-db"
  }
}