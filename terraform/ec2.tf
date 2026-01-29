resource "aws_security_group" "ec2_sg" {
  name   = "${var.name_prefix}-ec2-sg"
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_demo" {
  ami                         = "ami-0f54ea7480e4610de"
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name      = "${var.name_prefix}-ec2"
    ManagedBy = "terraform"
  }
}