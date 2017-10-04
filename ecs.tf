resource "aws_ecs_cluster" "data_engineering_cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

# Taskflow scheduler

data "template_file" "taskflow_scheduler_task_definition" {
  template = "${file("${path.module}/task_definitions/taskflow_scheduler.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/taskflow-scheduler:5b2dbf2498d910fc54bf882738b470c3f00e8aaf"
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
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/taskflow-api-server:5b2dbf2498d910fc54bf882738b470c3f00e8aaf"
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
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/api-gateway-gateway:747a96a1a1eb0dd2b01081a428b0f6bc7ab6a7b5-v3"
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

# Redash Webserver

data "template_file" "redash_webserver_task_definition" {
  template = "${file("${path.module}/task_definitions/redash_webserver.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/redash:7f4c9e652fee330e5c1f2ab8ef7dcb0f6e43f367"
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
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    elb_name = "${aws_elb.redash_webserver.id}"
    container_name   = "redash_webserver"
    container_port   = "5003"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.redash_webserver",
  ]
}

# Redash Worker

data "template_file" "redash_worker_task_definition" {
  template = "${file("${path.module}/task_definitions/redash_worker.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/redash:26d78d43919872f66bdd988fa8ab52489230c3fd"
    container_name   = "redash_worker"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.redash_worker.name}"
  }
}

resource "aws_ecs_task_definition" "redash_worker_task_definition" {
  family                = "${var.name_prefix}-redash-worker"
  task_role_arn         = "${aws_iam_role.redash.arn}"
  container_definitions = "${data.template_file.redash_worker_task_definition.rendered}"
}

resource "aws_ecs_service" "redash_worker" {
  name            = "${var.name_prefix}-redash-worker"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.redash_worker_task_definition.arn}"
  desired_count   = 1
}

# Superset Webserver

data "template_file" "superset_webserver_task_definition" {
  template = "${file("${path.module}/task_definitions/superset_webserver.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/superset:2ce760641261a3d8d74ea97aaea562e7ed6553b9"
    container_name   = "superset_webserver"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.superset_webserver.name}"
  }
}

resource "aws_ecs_task_definition" "superset_webserver_task_definition" {
  family                = "${var.name_prefix}-superset-webserver"
  task_role_arn         = "${aws_iam_role.superset.arn}"
  container_definitions = "${data.template_file.superset_webserver_task_definition.rendered}"
}

resource "aws_ecs_service" "superset_webserver" {
  name            = "${var.name_prefix}-superset-webserver"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.superset_webserver_task_definition.arn}"
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    elb_name = "${aws_elb.superset_webserver.id}"
    container_name   = "superset_webserver"
    container_port   = "5004"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.superset_webserver",
  ]
}
