provider "aws" {
  region = "us-east-2"
}


resource "aws_s3_bucket" "pr_bucket" {
  bucket = "kate-morozova-tf-lesson"
  acl    = "private"
}

resource "aws_instance" "my_server" {
  ami                    = "ami-03657b56516ab7912"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_server.id]
  subnet_id              = "subnet-0b0db19b4606f0177"
  depends_on             = [aws_s3_bucket.pr_bucket]
  tags = {
    Name  = "My server by terraform"
    Owner = "Kate Morozova"
  }
}

resource "aws_security_group" "sg_server" {
  name        = "SG for server by terraform"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "my-vpc"
  }
}

resource "null_resource" "private_ip" {
  provisioner "local-exec" {
    command = " echo private ip: ${aws_instance.my_server.private_ip}"
  }
}

#terraform destroy -target aws_instance.my_server -target aws_s3_bucket.pr_bucket -target aws_security_group.sg_server -target null_resource.private_ip
