data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "data_engineering_vpc_ssh" {
  name = "${var.name_prefix}-vpc-ssh"
  description = "Allows inbound SSH traffic within the VPC"
  vpc_id = "${aws_vpc.data_engineering.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22

    self = true
  }

  tags {
    Name = "${var.name_prefix}-vpc-ssh"
    Department = "${var.department}"
  }
}

resource "aws_security_group" "data_engineering_open_ssh" {
  name = "${var.name_prefix}-open-ssh"
  description = "Allow all inbound SSH traffic"
  vpc_id = "${aws_vpc.data_engineering.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name_prefix}-open-ssh"
    Department = "${var.department}"
  }
}

resource "aws_eip" "data_engineering_bastion" {
  instance = "${aws_instance.data_engineering_bastion.id}"
  vpc = true
}

resource "aws_instance" "data_engineering_bastion" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.data_engineering.0.id}"

  vpc_security_group_ids = [
    "${aws_security_group.data_engineering_open_ssh.id}",
    "${aws_security_group.data_engineering_vpc_ssh.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = 40
  }

  tags {
    Name = "${var.name_prefix}-bastion"
    Department = "${var.department}"
  }
}

resource "aws_eip" "data_engineering_tunnel_gateway" {
  instance = "${aws_instance.data_engineering_tunnel_gateway.id}"
  vpc = true
}

resource "aws_security_group" "data_engineering_tunnel_gateway" {
  name = "${var.name_prefix}-tunnel-gateway"
  description = "Allow VPC traffic to tunnel gateway"
  vpc_id = "${aws_vpc.data_engineering.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = ["10.0.0.0/16"] # from within VPC
  }

  tags {
    Name = "${var.name_prefix}-tunnel-gateway"
    Department = "${var.department}"
  }
}

data "template_file" "data_engineering_tunnel_gateway_user_data" {
  template = "${file("${path.module}/user_data/basic_debian_instance.tpl")}"

  vars {
    keytothecity_config_name = "tunnel_gateway"
    keytothecity_config = "${var.keytothecity_config}"
  }
}

resource "aws_instance" "data_engineering_tunnel_gateway" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.data_engineering.0.id}"
  user_data = "${data.template_file.data_engineering_tunnel_gateway_user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.data_engineering_tunnel_gateway.name}"

  vpc_security_group_ids = [
    "${aws_security_group.data_engineering_open_ssh.id}",
    "${aws_security_group.data_engineering_tunnel_gateway.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = 40
  }

  tags {
    Name = "${var.name_prefix}-tunnel-gateway"
    Department = "${var.department}"
  }
}
