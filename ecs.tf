resource "aws_ecs_cluster" "data_engineering_cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

# Taskflow scheduler

data "template_file" "taskflow_scheduler_task_definition" {
  template = "${file("${path.module}/task_definitions/taskflow_scheduler.json")}"

  vars {
    image_url        = "676612114792.dkr.ecr.us-east-1.amazonaws.com/taskflow-scheduler:d5d8f8869e1b442890fd89194e3b94c96de048ae"
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
