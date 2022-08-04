resource "google_workflows_workflow" "demo_workflow" {
  project = var.project_id
  name          = "demo_workflow"
  region        = var.location
  description   = "demo for workflows"
  service_account = "${google_service_account.sa.email}"
  source_contents = <<-EOF
  main:
    params: [args]
    steps:
      - copyToBigQueryFromS3:
          call: googleapis.bigquerydatatransfer.v1.projects.locations.transferConfigs.startManualRuns
          args:
            parent: "${google_bigquery_data_transfer_config.s3_import.name}"
            body:
              requestedRunTime: $${time.format(sys.now() + 30)}
          result: runsResp
      - create_nyc_citibike_time_series_data:
          call: googleapis.bigquery.v2.jobs.insert
          args:
            projectId: "${var.project_id}"
            body:
              jobReference:
                jobId: $${sys.get_env("GOOGLE_CLOUD_WORKFLOW_EXECUTION_ID")+"_series"}
                location: "${var.location}"
                projectId: "${var.project_id}"
              configuration:
                query:
                  query: >
                    WITH input_time_series AS
                    (
                      SELECT
                        start_station_name,
                        EXTRACT(DATE FROM starttime) AS date,
                        COUNT(*) AS num_trips
                      FROM
                        `${var.project_id}`.${var.bigquery_dataset}.`${var.bigquery_imported_table}`
                      GROUP BY
                        start_station_name, date
                    )
                    SELECT table_1.*
                    FROM input_time_series AS table_1
                    INNER JOIN (
                      SELECT start_station_name,  COUNT(*) AS num_points
                      FROM input_time_series
                      GROUP BY start_station_name) table_2
                    ON
                      table_1.start_station_name = table_2.start_station_name
                    WHERE
                      num_points > 400
                  destinationTable:
                    projectId: "${var.project_id}"
                    datasetId: "${var.bigquery_dataset}"
                    tableId: "nyc_citibike_time_series"
                  create_disposition: "CREATE_IF_NEEDED"
                  write_disposition: "WRITE_TRUNCATE"
                  allowLargeResults: true
                  useLegacySql: false
      - create_model:
          try:
            call: googleapis.bigquery.v2.jobs.insert
            args:
              projectId: "${var.project_id}"
              body:
                jobReference:
                  jobId: $${sys.get_env("GOOGLE_CLOUD_WORKFLOW_EXECUTION_ID")+"_model"}
                  location: "${var.location}"
                  projectId: "${var.project_id}"
                configuration:
                  query:
                    query: >
                      CREATE OR REPLACE MODEL ${var.bigquery_dataset}.nyc_citibike_arima_model_default
                      OPTIONS (model_type = 'ARIMA_PLUS',
                        time_series_timestamp_col = 'date',
                        time_series_data_col = 'num_trips',
                        time_series_id_col = 'start_station_name'
                      ) AS
                      SELECT *
                        FROM ${var.bigquery_dataset}.nyc_citibike_time_series
                      WHERE date < '2014-01-01'
                    useLegacySql: false
          retry: $${http.default_retry}
      - prediction:
          parallel:
            branches:
              - prediction_to_table:
                  steps:
                    - create_predction_result_table:
                        call: googleapis.bigquery.v2.jobs.insert
                        args:
                          projectId: "${var.project_id}"
                          body:
                            jobReference:
                              jobId: $${sys.get_env("GOOGLE_CLOUD_WORKFLOW_EXECUTION_ID")+"_prediction"}
                              location: "${var.location}"
                              projectId: "${var.project_id}"
                            configuration:
                              query:
                                query: >
                                  SELECT
                                    *
                                  FROM
                                    ML.FORECAST(MODEL ${var.bigquery_dataset}.nyc_citibike_arima_model_default,
                                      STRUCT(3 AS horizon,
                                        0.9 AS confidence_level))
                                destinationTable:
                                  projectId: "${var.project_id}"
                                  datasetId: "${var.bigquery_dataset}"
                                  tableId: "nyc_citibike_prediction_result"
                                create_disposition: "CREATE_IF_NEEDED"
                                write_disposition: "WRITE_TRUNCATE"
                                allowLargeResults: true
                                useLegacySql: false
              - prediction_to_gcs:
                  steps:
                    - export_prediction_to_gcs:
                        call: googleapis.bigquery.v2.jobs.insert
                        args:
                          projectId: "${var.project_id}"
                          body:
                            configuration:
                              query:
                                query: >
                                  EXPORT DATA OPTIONS(
                                    uri='${google_storage_bucket.demo-workflows-bucket.url}/*.csv.gz',
                                    format='CSV',
                                    header=true,
                                    field_delimiter=','
                                  ) AS
                                  SELECT
                                    *
                                  FROM
                                    ML.FORECAST(MODEL ${var.bigquery_dataset}.nyc_citibike_arima_model_default,
                                      STRUCT(3 AS horizon,
                                        0.9 AS confidence_level))
                                useLegacySql: false
      - the_end:
          return: "SUCCESS"
EOF
}
