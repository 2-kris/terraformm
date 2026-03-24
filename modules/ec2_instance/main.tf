variable "aws_vpc_cidr" {
  default = "10.0.0.0/16"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "my-vpc-${terraform.workspace}"
  }
}

resource "aws_key_pair" "my-key" {
  key_name   = "my-key-${terraform.workspace}"
  public_key = file("C:/Users/krishnamisal/.ssh/id_ed25519.pub")

}

resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

resource "aws_route_table_association" "my-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.my-route-table.id
}

resource "aws_security_group" "my-security-group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.my-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.my-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_5000_ipv4" {
  security_group_id = aws_security_group.my-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5000
  ip_protocol       = "tcp"
  to_port           = 5000
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.my-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.my-security-group.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "example" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  key_name                    = aws_key_pair.my-key.key_name
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.my-security-group.id]
  associate_public_ip_address = true

  tags = {
    Name = "HelloWorld-2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/Users/krishnamisal/.ssh/id_ed25519")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [
    "set -e",
    "sudo apt update -y",
    "sudo apt install python3-venv -y",

    # Create virtual environment
    "python3 -m venv /home/ubuntu/venv",

    # Install Flask inside venv
    "/home/ubuntu/venv/bin/pip install flask",

    "while [ ! -f /home/ubuntu/app.py ]; do sleep 2; done",

    # Go to app directory
    "chmod +x /home/ubuntu/app.py",

    "sleep 5", # Wait for a few seconds to ensure that the Flask app is fully copied before trying to run it

    "ls -l /home/ubuntu/", # List the app.py file to verify that it exists and has the correct permissions

    # Run app in background
    "nohup /home/ubuntu/venv/bin/python /home/ubuntu/app.py > app.log 2>&1 &",

    "sleep 3",
    "ps aux | grep app.py >> /home/ubuntu/app.log"
    ]
  }
}