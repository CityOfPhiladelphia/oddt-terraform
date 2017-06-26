resource "aws_elasticache_cluster" "redash" {
  cluster_id           = "redash"
  engine               = "redis"
  engine_version       = "3.2.4"
  node_type            = "cache.t2.small"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  subnet_group_name = "${aws_elasticache_subnet_group.data_engineering_redis.name}"
  security_group_ids   = ["${aws_security_group.data_engineering_redis.id}"]

  tags {
      Name = "${var.name_prefix}-routing-table"
      Department = "${var.department}"
  }
}

resource "aws_elasticache_subnet_group" "data_engineering_redis" {
  name       = "data-engineering-redis"
  subnet_ids = ["${aws_subnet.data_engineering.*.id}"]
}
