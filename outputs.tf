output "instance_security_group" {
  value = "${aws_security_group.oddt-data-ecs-instance-sg.id}"
}

output "launch_configuration" {
  value = "${aws_launch_configuration.oddt-data-ecs-instance.id}"
}

output "elb_hostname" {
  value = "${aws_alb.airflow.dns_name}"
}
