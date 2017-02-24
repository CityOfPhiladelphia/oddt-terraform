provider "aws" {
  region = "${var.aws_region}"
}

#### TODO: dropbox S3 and permissions
#### TODO: SSH tunnel gateway
#### TODO: bastion server ?

#### TODO: Domains?
#### TODO: SSL?

## EC2

### Network

data "aws_availability_zones" "available" {}

resource "aws_vpc" "data_engineering" {
  cidr_block = "10.0.0.0/16"

  tags {
      Name = "${var.name_prefix}-vpc"
      Department = "${var.department}"
  }
}

resource "aws_subnet" "data_engineering" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.data_engineering.cidr_block, 8, count.index)}"
  availability_zone = "${data_engineering.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-subnet-${self.availability_zone}"
      Department = "${var.department}"
  }
}

resource "aws_internet_gateway" "data_engineering" {
  vpc_id = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-gateway"
      Department = "${var.department}"
  }
}

resource "aws_route_table" "data_engineering" {
  vpc_id = "${aws_vpc.data_engineering.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.data_engineering.id}"
  }

  tags {
      Name = "${var.name_prefix}-routing-table"
      Department = "${var.department}"
  }
}

resource "aws_route_table_association" "data_routing_table_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.data_engineering.*.id, count.index)}"
  route_table_id = "${aws_route_table.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-routing-table-association"
      Department = "${var.department}"
  }
}

### Compute

resource "aws_autoscaling_group" "data_engineering_cluster" {
  name                 = "${var.name_prefix}-asg"
  vpc_zone_identifier  = ["${aws_subnet.data_engineering.*.id}"]
  min_size             = "${var.data_engineering_asg_min}"
  max_size             = "${var.data_engineering_asg_max}"
  desired_capacity     = "${var.data_engineering_asg_desired}"
  launch_configuration = "${aws_launch_configuration.data_engineering_cluster.name}"
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

# TODO: Add authorized_keys via user data?

data "template_file" "data_engineering_ecs_user_data" {
  template = "${file("${path.module}/user_data/ecs_service.tpl")}"

  vars {
    cluster_name = "${aws_ecs_cluster.data_engineering_cluster.name}"
  }
}

resource "aws_launch_configuration" "data_engineering_cluster" {
  security_groups = [
    "${aws_security_group.data_engineering_instance_sg.id}",
  ]

  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.ecs_optimized.id}"
  instance_type               = "${var.data_engineering_instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.data_engineering_cluster.name}"
  user_data                   = "${data.template_file.data_engineering_ecs_user_data.rendered}"
  associate_public_ip_address = true # TODO: remove once we create bastion in VPC? internet gateway?

  lifecycle {
    create_before_destroy = true # TODO: confirm this is needed
  }

  tags {
      Name = "${var.name_prefix}-ecs-launch-config"
      Department = "${var.department}"
  }
}

### Security

resource "aws_security_group" "data_engineering_elb_sg" {
  vpc_id = "${aws_vpc.data_engineering.id}"
  name   = "${var.name_prefix}-ecs-lbsg"

  ingress { ### !!!!!! TODO: what do do here before SSL and auth?
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
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
      Name = "${var.name_prefix}-ecs-elb-sg"
      Department = "${var.department}"
  }
}

resource "aws_security_group" "data_engineering_instance_sg" {
  vpc_id      = "${aws_vpc.data_engineering.id}"
  name        = "${var.name_prefix}-ecs-instance-sg"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = ["0.0.0.0/0"] ## TODO: lock this down more? Maybe after bastion
  }

  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080

    security_groups = [
      "${aws_security_group.data_engineering_elb_sg.id}",
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

## ECS

resource "aws_ecs_cluster" "data_engineering_cluster" {
  name = "${var.name_prefix}-ecs-cluster" ## ECS cluster name, not name tag

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

# Airflow webserver

data "template_file" "airflow_webserver_task_definition" {
  template = "${file("${path.module}/task_definitions/airflow_webserver.json")}"

  vars {
    image_url        = "phila_airflow:latest" ## TODO: need to publish image first
    container_name   = "airflow_webserver"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.data_engineering_ecs_cluster.name}"
  }
}

resource "aws_ecs_task_definition" "airflow_webserver_task_definition" {
  family                = "${name_prefix}-airflow"
  container_definitions = "${data.template_file.airflow_webserver_task_definition.rendered}"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

resource "aws_ecs_service" "airflow_webserver" {
  name            = "${name_prefix}-airflow-webserver"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.airflow_webserver_task_definition.arn}"
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    elb_name = "${aws_elb.airflow_webserver.id}"
    container_name   = "airflow_webserver"
    container_port   = "8080"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb_listener.airflow",
  ]

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

# Airflow scheduler

data "template_file" "airflow_scheduler_task_definition" {
  template = "${file("${path.module}/task_definitions/airflow_webserver.json")}"

  vars {
    image_url        = "phila_airflow:latest" ## TODO: need to publish image first
    container_name   = "airflow_scheduler"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.data_engineering_ecs_cluster.name}"
  }
}

resource "aws_ecs_task_definition" "airflow_scheduler_task_definition" {
  family                = "${name_prefix}-airflow"
  container_definitions = "${data.template_file.airflow_scheduler_task_definition.rendered}"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

# TODO: should other properties be used to keep the number of runnings tasks from going over one?

resource "aws_ecs_service" "airflow_scheduler" {
  name            = "${name_prefix}-airflow-scheduler"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.airflow_scheduler_task_definition.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs_service.name}"

  depends_on = [
    "aws_iam_role_policy.ecs_service",
  ]

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

# TODO: research placement strategies and constraints

## IAM

resource "aws_iam_role" "ecs_service" {
  name = "${name_prefix}-ecs-role"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "${name_prefix}-ecs-policy"
  role = "${aws_iam_role.ecs_service.name}"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "data_engineering_cluster" {
  name  = "${name_prefix}-ecs-instance-profile"
  roles = ["${aws_iam_role.data_engineering_cluster_instance.name}"]

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

resource "aws_iam_role" "data_engineering_cluster_instance" {
  name = "${name_prefix}-ecs-instance-role"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "data_engineering_cluster_instance_profile" {
  template = "${file("${path.module}/policies/data_engineering_ecs_instance_profile_policy.json")}"

  vars {
    container_log_group_arn = "${aws_cloudwatch_log_group.container.arn}"
    ecs_log_group_arn = "${aws_cloudwatch_log_group.ecs.arn}"
  }
}

resource "aws_iam_role_policy" "data_engineering_cluster_instance" {
  name   = "TfEcsExampleInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"

  tags {
      Name = "${var.name_prefix}-ecs-cluster"
      Department = "${var.department}"
  }
}

## ELB

resource "aws_elb" "airflow_webserver" {
  name = "${var.name_prefix}-airflow-webserver"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_elb_sg.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80 ## TODO: ssl
    lb_protocol = "http"
  }

  health_check { ## !!!!! TODO: double check this path with airflow webserver
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
      Name = "${var.name_prefix}-airflow-webserver-elb"
      Department = "${var.department}"
  }
}

## CloudWatch Logs

# TODO: group for ecs itself? - Can we pass this without creating the agent ourselves?

resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.name_prefix}/ecs-agent"

  tags {
      Name = "${var.name_prefix}-logs-ecs-agent"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "container" {
  name = "${var.name_prefix}/ecs-containers"

  tags {
      Name = "${var.name_prefix}-ecs-containers"
      Department = "${var.department}"
  }
}
