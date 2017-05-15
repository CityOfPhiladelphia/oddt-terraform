## AMIs

data "aws_ami" "ubuntu" {
  filter {
    name = "image-id"
    values = ["ami-2757f631"] # locking, this is used by individually launched instances
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "ecs_optimized" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # Amazon
}

## Bastion and Tunnel gateway

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

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["76.161.206.10/32"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080

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

## ECS Cluster

resource "aws_autoscaling_group" "data_engineering_cluster" {
  name                 = "${var.name_prefix}-ecs-asg"
  vpc_zone_identifier  = ["${aws_subnet.data_engineering.*.id}"]
  min_size             = "${var.data_engineering_ecs_asg_min}"
  max_size             = "${var.data_engineering_ecs_asg_max}"
  desired_capacity     = "${var.data_engineering_ecs_asg_desired}"
  launch_configuration = "${aws_launch_configuration.data_engineering_cluster.name}"
}

data "template_file" "data_engineering_ecs_user_data" {
  template = "${file("${path.module}/user_data/ecs_instance.tpl")}"

  vars {
    cluster_name = "${aws_ecs_cluster.data_engineering_cluster.name}"
    keytothecity_config_name = "ecs_cluster"
    keytothecity_config = "${var.keytothecity_config}"
  }
}

resource "aws_launch_configuration" "data_engineering_cluster" {
  security_groups = [
    "${aws_security_group.data_engineering_ecs_instance.id}",
    "${aws_security_group.data_engineering_vpc_ssh.id}",
  ]

  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.ecs_optimized.id}"
  instance_type               = "${var.data_engineering_ecs_instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.data_engineering_cluster.name}"
  user_data                   = "${data.template_file.data_engineering_ecs_user_data.rendered}"
  associate_public_ip_address = true # needed in public subnet

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "data_engineering_airflow_elb" {
  vpc_id = "${aws_vpc.data_engineering.id}"
  name   = "${var.name_prefix}-airflow-elb-sg"

    ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags {
      Name = "${var.name_prefix}-airflow-elb-sg"
      Department = "${var.department}"
  }
}

resource "aws_security_group" "data_engineering_ecs_instance" {
  vpc_id      = "${aws_vpc.data_engineering.id}"
  name        = "${var.name_prefix}-ecs-instance-sg"

  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080

    cidr_blocks = ["10.0.0.0/16"]

    security_groups = [
      "${aws_security_group.data_engineering_airflow_elb.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
      Name = "${var.name_prefix}-ecs-instance-sg"
      Department = "${var.department}"
  }
}

resource "aws_security_group" "data_engineering_rds" {
  vpc_id      = "${aws_vpc.data_engineering.id}"
  name        = "${var.name_prefix}-rds-sg"

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432

    cidr_blocks = ["10.0.0.0/16"] # from within VPC
  }

  tags {
      Name = "${var.name_prefix}-rds-sg"
      Department = "${var.department}"
  }
}
