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
    taskflow_scheduler_log_group_arn = "${aws_cloudwatch_log_group.taskflow_scheduler.arn}"
    taskflow_api_server_log_group_arn = "${aws_cloudwatch_log_group.taskflow_api_server.arn}"
    api_gateway_api_log_group_arn = "${aws_cloudwatch_log_group.api_gateway_api.arn}"
    api_gateway_gateway_log_group_arn = "${aws_cloudwatch_log_group.api_gateway_gateway.arn}"
    redash_webserver_log_group_arn = "${aws_cloudwatch_log_group.redash_webserver.arn}"
    redash_worker_log_group_arn = "${aws_cloudwatch_log_group.redash_worker.arn}"
    superset_webserver_log_group_arn = "${aws_cloudwatch_log_group.superset_webserver.arn}"
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

## Taskflow containers

resource "aws_iam_role" "taskflow" {
  name = "${var.name_prefix}-taskflow-role"

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

resource "aws_iam_role_policy" "taskflow" {
  name = "${var.name_prefix}-taskflow-policy"
  role = "${aws_iam_role.taskflow.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "batch:listJobs",
        "batch:describeJobs",
        "batch:submitJob"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-data-dropbox/*",
        "arn:aws:s3:::phl-etl-staging/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::phl-etl-staging",
        "arn:aws:s3:::phl-schemas"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-schemas/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::eastern-state/taskflow"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.taskflow_eastern_state_prod.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

## Taskflow local dev

resource "aws_iam_user" "taskflow_local_dev" {
  name = "taskflow-dev"
}

resource "aws_iam_user_policy" "taskflow_local_dev" {
  name = "${var.name_prefix}-taskflow-local-dev-policy"
  user = "${aws_iam_user.taskflow_local_dev.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "batch:listJobs",
        "batch:describeJobs",
        "batch:submitJob"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-data-dropbox-dev/*",
        "arn:aws:s3:::phl-etl-staging-dev/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::phl-etl-staging-dev",
        "arn:aws:s3:::phl-schemas"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-schemas/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::eastern-state/taskflow"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.taskflow_eastern_state_dev.arn}"
      ]
    }
  ]
}
EOF
}

## Redash containers

resource "aws_iam_role" "redash" {
  name = "${var.name_prefix}-redash-role"

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

resource "aws_iam_role_policy" "redash" {
  name = "${var.name_prefix}-redash-policy"
  role = "${aws_iam_role.redash.name}"

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
        "arn:aws:s3:::eastern-state/redash"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.redash_eastern_state_prod.arn}"
      ]
    }
  ]
}
EOF
}

## Superset containers

resource "aws_iam_role" "superset" {
  name = "${var.name_prefix}-superset-role"

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

resource "aws_iam_role_policy" "superset" {
  name = "${var.name_prefix}-superset-policy"
  role = "${aws_iam_role.superset.name}"

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
        "arn:aws:s3:::eastern-state/superset"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.superset_eastern_state_prod.arn}"
      ]
    }
  ]
}
EOF
}

## API Gateway API containers

resource "aws_iam_role" "api_gateway_api" {
  name = "${var.name_prefix}-api-gateway-api-role"

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

resource "aws_iam_role_policy" "api_gateway_api" {
  name = "${var.name_prefix}-api-gateway-api-policy"
  role = "${aws_iam_role.api_gateway_api.name}"

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
        "arn:aws:s3:::eastern-state/api-gateway-api"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.api_gateway_api_eastern_state_prod.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:DeleteMessageBatch"
      ],
      "Resource": [
        "${aws_sqs_queue.api_gateway.arn}"
      ]
    }
  ]
}
EOF
}

## API Gateway Gateway containers

resource "aws_iam_role" "api_gateway_gateway" {
  name = "${var.name_prefix}-api-gateway-gateway-role"

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

resource "aws_iam_role_policy" "api_gateway_gateway" {
  name = "${var.name_prefix}-api-gateway-gateway-policy"
  role = "${aws_iam_role.api_gateway_gateway.name}"

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
        "arn:aws:s3:::eastern-state/api-gateway-gateway"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_kms_key.api_gateway_gateway_eastern_state_prod.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.api_gateway.arn}"
      ]
    }
  ]
}
EOF
}
