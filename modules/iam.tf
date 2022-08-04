## IAM settings
resource "google_project_iam_custom_role" "my-custom-role" {
  project     = var.project_id
  role_id     = var.custom_role_id
  title       = var.custom_role_id
  description = "custom role for bigquery data transfer service"
  permissions = [ "bigquery.models.create",
                  "bigquery.models.updateData",
                  "bigquery.models.updateMetadata",
                  "bigquery.models.export",
                  "bigquery.models.getData",
                  "bigquery.models.getMetadata",
                  "bigquery.tables.create",
                  "bigquery.tables.update",
                  "bigquery.tables.updateData",
                  "bigquery.tables.getData",
                  "bigquery.transfers.get",
                  "bigquery.transfers.update",
                  "bigquery.jobs.create"]
}

resource "google_service_account" "sa" {
  project = var.project_id
  account_id   = "demo-workflows-runner"
  display_name = "service account for workflows demo"
}

resource "google_project_iam_member" "role1" {
  project = var.project_id
  role    = "roles/bigquerydatatransfer.serviceAgent"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "role2" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "role3" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "role4" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.my-custom-role.role_id}"
  member  = "serviceAccount:${google_service_account.sa.email}"
}
