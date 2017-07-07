resource "aws_ecs_cluster" "data_engineering_cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

# Taskflow scheduler

data "template_file" "taskflow_scheduler_task_definition" {
  template = "${file("${path.module}/task_definitions/taskflow_scheduler.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/taskflow-scheduler:72be6889ac36c5a407feb38738428f27d748504b-v2"
    container_name   = "taskflow_scheduler"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.taskflow_scheduler.name}"
  }
}

resource "aws_ecs_task_definition" "taskflow_scheduler_task_definition" {
  family                = "${var.name_prefix}-taskflow-scheduler"
  task_role_arn         = "${aws_iam_role.taskflow.arn}"
  container_definitions = "${data.template_file.taskflow_scheduler_task_definition.rendered}"
}

resource "aws_ecs_service" "taskflow_scheduler" {
  name            = "${var.name_prefix}-taskflow-scheduler"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.taskflow_scheduler_task_definition.arn}"
  desired_count   = 1
  # we only want exactly one scheduler running at once
  deployment_maximum_percent = 100
  deployment_minimum_healthy_percent = 0
}

# Taskflow API server

data "template_file" "taskflow_api_server_task_definition" {
  template = "${file("${path.module}/task_definitions/taskflow_api_server.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/taskflow-api-server:eadd73c7fa6eb9d7cfcbe89a4859fa824df99eb1"
    container_name   = "taskflow_api_server"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.taskflow_api_server.name}"
  }
}

resource "aws_ecs_task_definition" "taskflow_api_server_task_definition" {
  family                = "${var.name_prefix}-taskflow-api-server"
  task_role_arn         = "${aws_iam_role.taskflow.arn}"
  container_definitions = "${data.template_file.taskflow_api_server_task_definition.rendered}"
}

resource "aws_ecs_service" "taskflow_api_server" {
  name            = "${var.name_prefix}-taskflow-api-server"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.taskflow_api_server_task_definition.arn}"
  iam_role        = "${aws_iam_role.ecs_service.name}"
  desired_count   = 2

  load_balancer {
    elb_name = "${aws_elb.taskflow_api_server.id}"
    container_name   = "taskflow_api_server"
    container_port   = "5000"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.taskflow_api_server",
  ]
}

# API Gateway API

data "template_file" "api_gateway_api_task_definition" {
  template = "${file("${path.module}/task_definitions/api_gateway_api.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/api-gateway-api:747a96a1a1eb0dd2b01081a428b0f6bc7ab6a7b5-v2"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.api_gateway_api.name}"
  }
}

resource "aws_ecs_task_definition" "api_gateway_api_task_definition" {
  family                = "${var.name_prefix}-api-gateway-api"
  task_role_arn         = "${aws_iam_role.api_gateway_api.arn}"
  container_definitions = "${data.template_file.api_gateway_api_task_definition.rendered}"
}

resource "aws_ecs_service" "api_gateway_api" {
  name            = "${var.name_prefix}-api-gateway-api"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.api_gateway_api_task_definition.arn}"
  iam_role        = "${aws_iam_role.ecs_service.name}"
  desired_count   = 2

  load_balancer {
    elb_name = "${aws_elb.api_gateway_api.id}"
    container_name   = "api_gateway_api"
    container_port   = "5001"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.api_gateway_api",
  ]
}

# API Gateway API Worker

data "template_file" "api_gateway_api_worker_task_definition" {
  template = "${file("${path.module}/task_definitions/api_gateway_api_worker.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/api-gateway-api:747a96a1a1eb0dd2b01081a428b0f6bc7ab6a7b5-v3"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.api_gateway_api.name}"
  }
}

resource "aws_ecs_task_definition" "api_gateway_api_worker_task_definition" {
  family                = "${var.name_prefix}-api-gateway-api-worker"
  task_role_arn         = "${aws_iam_role.api_gateway_api.arn}"
  container_definitions = "${data.template_file.api_gateway_api_worker_task_definition.rendered}"
}

resource "aws_ecs_service" "api_gateway_api_worker" {
  name            = "${var.name_prefix}-api-gateway-api-worker"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.api_gateway_api_worker_task_definition.arn}"
  desired_count   = 1

  depends_on = [
    "aws_iam_role_policy.ecs_service"
  ]
}

# API Gateway Gateway

data "template_file" "api_gateway_gateway_task_definition" {
  template = "${file("${path.module}/task_definitions/api_gateway_gateway.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/api-gateway-gateway:747a96a1a1eb0dd2b01081a428b0f6bc7ab6a7b5-v2"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.api_gateway_gateway.name}"
  }
}

resource "aws_ecs_task_definition" "api_gateway_gateway_task_definition" {
  family                = "${var.name_prefix}-api-gateway-gateway"
  task_role_arn         = "${aws_iam_role.api_gateway_gateway.arn}"
  container_definitions = "${data.template_file.api_gateway_gateway_task_definition.rendered}"
}

resource "aws_ecs_service" "api_gateway_gateway" {
  name            = "${var.name_prefix}-api-gateway-gateway"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.api_gateway_gateway_task_definition.arn}"
  iam_role        = "${aws_iam_role.ecs_service.name}"
  desired_count   = 2

  load_balancer {
    elb_name = "${aws_elb.api_gateway.id}"
    container_name   = "api_gateway_gateway"
    container_port   = "5002"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.api_gateway",
  ]
}

# Redash

data "template_file" "redash_webserver_task_definition" {
  template = "${file("${path.module}/task_definitions/redash_webserver.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/redash:99e13dd579aa340de9b36812ea9387f5d076e95e"
    container_name   = "redash_webserver"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.redash_webserver.name}"
  }
}

resource "aws_ecs_task_definition" "redash_webserver_task_definition" {
  family                = "${var.name_prefix}-redash-webserver"
  task_role_arn         = "${aws_iam_role.redash.arn}"
  container_definitions = "${data.template_file.redash_webserver_task_definition.rendered}"
}

resource "aws_ecs_service" "redash_webserver" {
  name            = "${var.name_prefix}-redash-webserver"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.redash_webserver_task_definition.arn}"
  desired_count   = 0
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    elb_name = "${aws_elb.redash_webserver.id}"
    container_name   = "redash_webserver"
    container_port   = "5000"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.redash_webserver",
  ]
}
