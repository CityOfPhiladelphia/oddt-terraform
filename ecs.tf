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
