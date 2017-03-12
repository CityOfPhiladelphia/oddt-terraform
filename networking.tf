data "aws_availability_zones" "available" {}

resource "aws_vpc" "data_engineering" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
      Name = "${var.name_prefix}-vpc"
      Department = "${var.department}"
  }
}

resource "aws_subnet" "data_engineering" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.data_engineering.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-subnet-${data.aws_availability_zones.available.names[count.index]}"
      Department = "${var.department}"
  }
}

resource "aws_internet_gateway" "data_engineering" {
  vpc_id = "${aws_vpc.data_engineering.id}"

  tags {
      Name = "${var.name_prefix}-gateway"
      Department = "${var.department}"
  }
}

resource "aws_route_table" "data_engineering" {
  vpc_id = "${aws_vpc.data_engineering.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.data_engineering.id}"
  }

  tags {
      Name = "${var.name_prefix}-routing-table"
      Department = "${var.department}"
  }
}

resource "aws_route_table_association" "data_routing_table_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.data_engineering.*.id, count.index)}"
  route_table_id = "${aws_route_table.data_engineering.id}"
}
