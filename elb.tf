resource "aws_elb" "redash_webserver" {
  name = "redash-webserver"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_redash_elb.id}"]

  listener {
    instance_port      = 5000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:676612114792:certificate/e5f3e671-6f0c-4204-8363-b0504dbd4d5f"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:5000"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}

resource "aws_elb" "taskflow_api_server" {
  name = "taskflow-api-server"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_taskflow_api_server_elb.id}"]

  listener {
    instance_port      = 5000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:676612114792:certificate/e5f3e671-6f0c-4204-8363-b0504dbd4d5f"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:5000"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}

resource "aws_elb" "api_gateway_api" {
  name = "api-gateway-api"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_api_gateway_api_elb.id}"]
  internal = true

  listener {
    instance_port      = 5001
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:5001"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}

resource "aws_elb" "api_gateway" {
  name = "api-gateway"
  subnets         = ["${aws_subnet.data_engineering.*.id}"]
  security_groups = ["${aws_security_group.data_engineering_api_gateway_gateway_elb.id}"]

  listener {
    instance_port      = 5002
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-1:676612114792:certificate/e5f3e671-6f0c-4204-8363-b0504dbd4d5f"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:5002"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
}
