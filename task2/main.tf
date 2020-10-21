provider "aws" {
  region = "us-east-2"
}

variable "conditional" {
  default = "1"
}
data "template_file" "user_data" {
  template = file("file.yaml")
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
  iam_instance_profile   = "${aws_iam_instance_profile.s3_role_profile.name}"
  user_data              = data.template_file.user_data.rendered
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

resource "aws_iam_role" "server_access_s3" {
  name               = "s3_role"
  count              = var.conditional == "1" ? 1 : 0
  assume_role_policy = <<EOF
{
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
           "Service": "ec2.amazonaws.com"
         },
         "Effect": "Allow",
         "Sid": ""
       }
     ]
}
EOF
}


resource "aws_iam_instance_profile" "s3_role_profile" {
  name = "s3_bucket_role"
  role = "${aws_iam_role.server_access_s3[0].name}"
}

resource "aws_iam_role_policy" "s3_bucket_policy" {
  name   = "s3_bucket_policy"
  role   = "${aws_iam_role.server_access_s3[0].id}"
  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": "*"
          }
      ]
}
EOF
}
