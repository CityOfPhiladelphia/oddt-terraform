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

resource "aws_cloudwatch_log_group" "taskflow_scheduler" {
  name = "${var.name_prefix}/taskflow-scheduler"

  tags {
      Name = "${var.name_prefix}-taskflow-scheduler"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "taskflow_api_server" {
  name = "${var.name_prefix}/taskflow-api-server"

  tags {
      Name = "${var.name_prefix}-taskflow-api-server"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_api" {
  name = "${var.name_prefix}/api-gateway-api"

  tags {
      Name = "${var.name_prefix}-api-gateway-api"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_gateway" {
  name = "${var.name_prefix}/api-gateway-gateway"

  tags {
      Name = "${var.name_prefix}-api-gateway-gateway"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "redash_webserver" {
  name = "${var.name_prefix}/redash-webserver"

  tags {
      Name = "${var.name_prefix}-redash-webserver"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "redash_worker" {
  name = "${var.name_prefix}/redash-worker"

  tags {
      Name = "${var.name_prefix}-redash-worker"
      Department = "${var.department}"
  }
}

resource "aws_cloudwatch_log_group" "superset_webserver" {
  name = "${var.name_prefix}/superset-webserver"

  tags {
      Name = "${var.name_prefix}-superset-webserver"
      Department = "${var.department}"
  }
}
