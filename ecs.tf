resource "aws_ecs_cluster" "data_engineering_cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

# Airflow webserver

data "template_file" "airflow_webserver_task_definition" {
  template = "${file("${path.module}/task_definitions/airflow_webserver.json")}"

  vars {
    image_url        = "cityofphiladelphia/airflow:8590b5c96c59aee3c82c16cc1bc1a63235ef4217"
    container_name   = "airflow_webserver"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.container.name}"
  }
}

resource "aws_ecs_task_definition" "airflow_webserver_task_definition" {
  family                = "${var.name_prefix}-airflow"
  task_role_arn         = "${aws_iam_role.airflow.name}"
  container_definitions = "${data.template_file.airflow_webserver_task_definition.rendered}"
}

resource "aws_ecs_service" "airflow_webserver" {
  name            = "${var.name_prefix}-airflow-webserver"
  cluster         = "${aws_ecs_cluster.data_engineering_cluster.id}"
  task_definition = "${aws_ecs_task_definition.airflow_webserver_task_definition.arn}"
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    elb_name = "${aws_elb.airflow_webserver.id}"
    container_name   = "airflow_webserver"
    container_port   = "8080"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_elb.airflow_webserver",
  ]
}