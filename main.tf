provider "aws" {
  region = "${var.aws_region}"
}

#### TODO: !!!!!! name and department tags?
#### TODO: !!!!!! underscores vs hyphens

## EC2

### Network

data "aws_availability_zones" "available" {}

resource "aws_vpc" "oddt-data" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "oddt-data" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.oddt-data.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.oddt-data.id}"
}

resource "aws_internet_gateway" "oddt-data-gateway" {
  vpc_id = "${aws_vpc.oddt-data.id}"
}

resource "aws_route_table" "oddt-data-routing-table" {
  vpc_id = "${aws_vpc.oddt-data.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.oddt-data-gateway.id}"
  }
}

resource "aws_route_table_association" "oddt-data-routing-table-association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.oddt-data.*.id, count.index)}"
  route_table_id = "${aws_route_table.oddt-data-routing-table.id}"
}

### Compute

# TODO: Get ECS optimized AMI thorugh `data "aws_ami" ...`

# TODO: add ECS agent config to instance user data?

# TODO: Create two EC2 instances in two AZs using `resource "aws_launch_configuration" ..`

### Security

# TODO: Data VPC ELB security group `resource "aws_security_group" "oddt-data-elb-sg" { ...`

# TODO: ECS cluster instance security group

## ECS

resource "aws_ecs_cluster" "oddt-data" {
  name = "oddt-data"
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
