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

resource "aws_s3_bucket" "phl-etl-staging" {
  bucket = "phl-etl-staging"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}

resource "aws_s3_bucket" "phl-etl-staging-dev" {
  bucket = "phl-etl-staging-dev"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}

resource "aws_s3_bucket" "phl-schemas" {
  bucket = "phl-schemas"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}

resource "aws_s3_bucket" "phl-data-build-assets" {
  bucket = "phl-data-build-assets"
  acl = "private"
  website {
    index_document = "index.html"
  }
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::676612114792:root"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::phl-data-build-assets/*"
      ]
    },
    {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::phl-data-build-assets/*"
    }
  ]
}
EOF

  tags {
    Department = "${var.department}"
  }
}

resource "aws_s3_bucket" "phl-geocode-cache" {
  bucket = "phl-geocode-cache"
  acl = "private"

  tags {
    Department = "${var.department}"
  }
}
