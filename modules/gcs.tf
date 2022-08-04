## Cloud Storage settings
resource "google_storage_bucket" "demo-workflows-bucket" {
  project                     = var.project_id
  name                        = var.gcs_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
}
