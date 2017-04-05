variable "name_prefix" {
  description = "A string of text to place before each Name tag"
  default     = "oddt-data-engineering"
}

variable "department" {
  description = "City / organizational department"
  default     = "oddt"
}

variable "aws_region" {
  default     = "us-east-1"
}

variable "key_name" {
  description = "RSA key pair to place on created instances"
  default     = "andrew.madonna"
}

variable "keytothecity_config" {
  description = "S3 keytothecity config file"
  default     = "s3://oddt-pub-keys/keytothecity.yml"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "3"
}

variable "data_engineering_ecs_instance_type" {
  description = "Instance type to use for the data engineering service cluster"
  default     = "t2.medium"
}

variable "data_engineering_ecs_asg_min" {
  description = "Minium number of instaces for the data engineering Docker cluster auto scaling group"
  default     = "1"
}

variable "data_engineering_ecs_asg_max" {
  description = "Maximum number of instaces for the data engineering Docker cluster auto scaling group"
  default     = "4"
}

variable "data_engineering_ecs_asg_desired" {
  description = "Desired number of instaces for the data engineering Docker cluster auto scaling group"
  default     = "3"
}
