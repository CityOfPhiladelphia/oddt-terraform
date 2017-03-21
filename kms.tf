resource "aws_kms_key" "airflow_eastern_state_prod" {
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "airflow_eastern_state_prod_alias" {
  name = "alias/airflow-eastern-state-prod"
  target_key_id = "${aws_kms_key.airflow_eastern_state_prod.key_id}"
}

resource "aws_kms_key" "airflow_eastern_state_dev" {
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "airflow_eastern_state_dev_alias" {
  name = "alias/airflow-eastern-state-dev"
  target_key_id = "${aws_kms_key.airflow_eastern_state_dev.key_id}"
}
