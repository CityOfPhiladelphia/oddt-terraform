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