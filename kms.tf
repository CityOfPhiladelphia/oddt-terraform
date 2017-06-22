resource "aws_kms_key" "taskflow_eastern_state_prod" {
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "taskflow_eastern_state_prod_alias" {
  name = "alias/taskflow-eastern-state-prod"
  target_key_id = "${aws_kms_key.taskflow_eastern_state_prod.key_id}"
}

resource "aws_kms_key" "taskflow_eastern_state_dev" {
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "taskflow_eastern_state_dev_alias" {
  name = "alias/taskflow-eastern-state-dev"
  target_key_id = "${aws_kms_key.taskflow_eastern_state_dev.key_id}"
}

resource "aws_kms_key" "redash_eastern_state_prod" {
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "redash_eastern_state_prod_alias" {
  name = "alias/redash-eastern-state-prod"
  target_key_id = "${aws_kms_key.redash_eastern_state_prod.key_id}"
}
