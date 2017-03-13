resource "aws_s3_bucket" "eastern-state" {
  bucket = "eastern-state"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}
