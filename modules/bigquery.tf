resource "google_bigquery_dataset" "demo_workflows_dataset" {
  dataset_id                 = var.bigquery_dataset
  delete_contents_on_destroy = false
  location                   = var.location
  project                    = var.project_id
}

# Wait for getting prepared for dataset metadata creating asynchronously
resource "null_resource" "previous" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "30s"
}

resource "google_bigquery_table" "imported_table_from_s3" {
  depends_on = [time_sleep.wait_30_seconds]

  dataset_id          = var.bigquery_dataset
  description         = "demo data from https://console.cloud.google.com/bigquery?p=bigquery-public-data&d=new_york&t=citibike_trips&page=table&_ga=2.266532234.565906055.1657510394-1561217234.1656911705&_gac=1.186846938.1657262443.CjwKCAjwiJqWBhBdEiwAtESPaKw2WoEz3rQPIH6JDiLjueclijhsdKLSnvn5QriJtytJEdv6mtoMyBoCIc8QAvD_BwE"
  deletion_protection = false
  project     = var.project_id
  schema      = "[{\"description\":\"Trip Duration (in seconds)\",\"mode\":\"NULLABLE\",\"name\":\"tripduration\",\"type\":\"INTEGER\"},{\"description\":\"Start Time\",\"mode\":\"NULLABLE\",\"name\":\"starttime\",\"type\":\"TIMESTAMP\"},{\"description\":\"Stop Time\",\"mode\":\"NULLABLE\",\"name\":\"stoptime\",\"type\":\"TIMESTAMP\"},{\"description\":\"Start Station ID\",\"mode\":\"NULLABLE\",\"name\":\"start_station_id\",\"type\":\"INTEGER\"},{\"description\":\"Start Station Name\",\"mode\":\"NULLABLE\",\"name\":\"start_station_name\",\"type\":\"STRING\"},{\"description\":\"Start Station Latitude\",\"mode\":\"NULLABLE\",\"name\":\"start_station_latitude\",\"type\":\"FLOAT\"},{\"description\":\"Start Station Longitude\",\"mode\":\"NULLABLE\",\"name\":\"start_station_longitude\",\"type\":\"FLOAT\"},{\"description\":\"End Station ID\",\"mode\":\"NULLABLE\",\"name\":\"end_station_id\",\"type\":\"INTEGER\"},{\"description\":\"End Station Name\",\"mode\":\"NULLABLE\",\"name\":\"end_station_name\",\"type\":\"STRING\"},{\"description\":\"End Station Latitude\",\"mode\":\"NULLABLE\",\"name\":\"end_station_latitude\",\"type\":\"FLOAT\"},{\"description\":\"End Station Longitude\",\"mode\":\"NULLABLE\",\"name\":\"end_station_longitude\",\"type\":\"FLOAT\"},{\"description\":\"Bike ID\",\"mode\":\"NULLABLE\",\"name\":\"bikeid\",\"type\":\"INTEGER\"},{\"description\":\"User Type (Customer = 24-hour pass or 7-day pass user, Subscriber = Annual Member)\",\"mode\":\"NULLABLE\",\"name\":\"usertype\",\"type\":\"STRING\"},{\"description\":\"Year of Birth\",\"mode\":\"NULLABLE\",\"name\":\"birth_year\",\"type\":\"INTEGER\"},{\"description\":\"Gender (unknown, male, female)\",\"mode\":\"NULLABLE\",\"name\":\"gender\",\"type\":\"STRING\"}]"
  table_id    = var.bigquery_imported_table
}

resource "google_project_iam_member" "permissions" {
  project = var.project_id
  role   = "roles/iam.serviceAccountShortTermTokenMinter"
  member = var.admin_user
}

resource "google_bigquery_data_transfer_config" "s3_import" {
  depends_on = [google_project_iam_member.permissions]

  project                = var.project_id
  display_name           = "demo transfer from Amazon S3"
  location               = var.location
  data_source_id         = "amazon_s3"
  schedule               = ""
  schedule_options {
    disable_auto_scheduling = true
  }
  destination_dataset_id = var.bigquery_dataset
  params = {
    destination_table_name_template = var.bigquery_imported_table
    data_path                       = var.s3_data_path
    access_key_id                   = var.s3_access_key_id
    secret_access_key               = var.s3_secret_access_key
    file_format                     = "CSV"
    field_delimiter                 = ","
    skip_leading_rows               = "1"
  }
}


