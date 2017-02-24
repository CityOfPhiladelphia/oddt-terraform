provider "aws" {
  region = "${var.aws_region}"
}

#### TODO: dropbox S3 and permissions
#### TODO: Domains?
#### TODO: SSL?

## EC2

### Network

data "aws_availability_zones" "available" {}

resource "aws_vpc" "data_engineering" {
  cidr_block = "10.0.0.0/16"

  tags {
      Name = "${var.name_prefix}"
      Department = "${var.department}"
  }
}

resource "aws_subnet" "data_engineering" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.data_engineering.cidr_block, 8, count.index)}"
  availability_zone = "${data_engineering.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-${self.availability_zone}"
      Department = "${var.department}"
  }
}

resource "aws_internet_gateway" "data_engineering" {
  vpc_id = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}"
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
      Name = "${var.name_prefix}"
      Department = "${var.department}"
  }
}

resource "aws_route_table_association" "data_routing_table_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.data_engineering.*.id, count.index)}"
  route_table_id = "${aws_route_table.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}"
      Department = "${var.department}"
  }
}

### Compute

# TODO: Get ECS optimized AMI thorugh `data "aws_ami" ...`

# TODO: add ECS agent config to instance user data?

# TODO: Create two EC2 instances in two AZs using `resource "aws_launch_configuration" ..`

### Security

# TODO: Data VPC ELB security group `resource "aws_security_group" "data_elb_sg" { ...`

# TODO: ECS cluster instance security group

## ECS

resource "aws_ecs_cluster" "data" {
  name = "${var.name_prefix}" ## ECS cluster name, not name tag

  tags {
      Name = "${var.name_prefix}"
      Department = "${var.department}"
  }
}

# TODO: tasks for airflow-webserver and airflow-scheduler `data "template_file" "task_definition" {` .. `resource "aws_ecs_task_definition" "..." {`

# TODO: service for airflow-webserver and airflow-scheduler `resource "aws_ecs_service" ...` - airflow-scheduler should have max 1 instance and higher memory / CPU

## IAM

# TODO: ecs service role and policy - used by ECS itself to create/alter resources

# TODO: ecs instance profile, role, and policy 

## ELB

# TODO: Create ELB for airflow-webserver

## CloudWatch Logs

# TODO: group for ecs itself? - Can we pass this without creating the agent ourselves?

# TODO: group for tasks?
