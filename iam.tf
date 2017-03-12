## ECS cluster intance

resource "aws_iam_role" "data_engineering_cluster_instance" {
  name = "${var.name_prefix}-ecs-instance-role"

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

resource "aws_iam_instance_profile" "data_engineering_cluster" {
  name  = "${var.name_prefix}-ecs-instance-profile"
  roles = ["${aws_iam_role.data_engineering_cluster_instance.name}"]
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
  role   = "${aws_iam_role.data_engineering_cluster_instance.name}"
  policy = "${data.template_file.data_engineering_cluster_instance_profile.rendered}"
}

## Tunnel Gateway

resource "aws_iam_role" "data_engineering_tunnel_gateway" {
  name = "${var.name_prefix}-tunnel-gateway"

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

resource "aws_iam_instance_profile" "data_engineering_tunnel_gateway" {
  name  = "${var.name_prefix}-tunnel-gateway"
  roles = ["${aws_iam_role.data_engineering_tunnel_gateway.name}"]
}

data "template_file" "data_engineering_tunnel_gateway_policy_template" {
  template = "${file("${path.module}/policies/data_engineering_tunnel_instance_profile_policy.json")}"
}

resource "aws_iam_role_policy" "data_engineering_tunnel_gateway_policy" {
  name   = "TunnelGatewayPolicy"
  role   = "${aws_iam_role.data_engineering_tunnel_gateway.name}"
  policy = "${data.template_file.data_engineering_tunnel_gateway_policy_template.rendered}"
}

