resource "aws_elb" "airflow_webserver" {
  name = "airflow-webserver"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_airflow_elb.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80 ## TODO: ssl
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:8080"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}
