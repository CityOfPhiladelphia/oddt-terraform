resource "aws_s3_bucket" "eastern-state" {
  bucket = "eastern-state"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}

resource "aws_s3_bucket" "phl-data-dropbox-dev" {
  bucket = "phl-data-dropbox-dev"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}
