resource "aws_sqs_queue" "api_gateway" {
  name                            = "api-gateway"
  visibility_timeout_seconds      = 60
  message_retention_seconds       = 1209600
}
