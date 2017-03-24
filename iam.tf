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

## ECS

resource "aws_iam_role" "ecs_service" {
  name = "${var.name_prefix}-ecs-role"

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
  name = "${var.name_prefix}-ecs-policy"
  role = "${aws_iam_role.ecs_service.name}"

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

## Airflow containers

resource "aws_iam_role" "airflow" {
  name = "${var.name_prefix}-airflow-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "airflow" {
  name = "${var.name_prefix}-airflow-policy"
  role = "${aws_iam_role.airflow.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::eastern-state/airflow"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.airflow_eastern_state_prod.arn}"
      ]
    }
  ]
}
EOF
}

## Airflow local dev

resource "aws_iam_user" "airflow_local_dev" {
  name = "airflow-dev"
}

resource "aws_iam_user_policy" "airflow_local_dev" {
  name = "${var.name_prefix}-airflow-local-dev-policy"
  user = "${aws_iam_user.airflow_local_dev.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-data-dropbox-dev/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::eastern-state/airflow"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.airflow_eastern_state_dev.arn}"
      ]
    }
  ]
}
EOF
}
