variable "name_prefix" {
  default     = "oddt-data-engineering"
}

variable "department" {
  default     = "oddt"
}

variable "aws_region" {
  default     = "us-east-1"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}
