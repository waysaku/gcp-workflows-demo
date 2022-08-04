variable "PROJECT_ID" {}
variable "ADMIN_USER" {}
variable "S3_DATA_PATH" {}
variable "S3_ACCESS_KEY_ID" {}
variable "S3_SECRET_ACCESS_KEY" {}

module "main" {
  source = "./modules"
  project_id              = var.PROJECT_ID
  admin_user              = var.ADMIN_USER
  s3_data_path            = var.S3_DATA_PATH
  s3_access_key_id        = var.S3_ACCESS_KEY_ID
  s3_secret_access_key    = var.S3_SECRET_ACCESS_KEY

  custom_role_id          = "BigqueryTransferRoleForDemo13"
  location                = "us-central1"
  bigquery_dataset        = "demo_workflows_dataset"
  bigquery_imported_table = "imported-table-from-s3"
  gcs_bucket_name         = "demo-workflows-bucket"
}
