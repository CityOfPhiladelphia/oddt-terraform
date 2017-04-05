resource "aws_elb" "airflow_webserver" {
  name = "airflow-webserver"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_airflow_elb.id}"]

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:676612114792:certificate/a8ea1042-fe3e-44cc-9a64-b416909118c1"
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
