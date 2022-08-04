## What is this demo for?
This demo shows you that [Workflows](https://cloud.google.com/workflows?hl=ja) by Google Cloud will control running Tasks below sequencially.
1. Import CSV data from AWS s3 using [BigQuery Data Transfer Service](https://cloud.google.com//bigquery-transfer/docs/introduction?hl=ja).
2. Extract and Transform data to time series data.
3. Build a prediction model using BigQuery ML
4. Export prediction result to GCS as CSV and BigQuery Table

## Prerequired
Upload CSV data ( `./demodata/bquxjob_72fc98c1_181f02c46d3.csv` ) to AWS S3 and create an IAM user on AWS. Then get some information related to access the CSV on AWS. ([ref](https://cloud.google.com/bigquery-transfer/docs/s3-transfer-intro?hl=ja#s3-uri))

This demodata is a part of `new_york.citibike_trips` data in bigquery public dataset. ([link](https://console.cloud.google.com/marketplace/product/city-of-new-york/nyc-citi-bike?hl=ja&project=waysaku-mlops-demo-crooz))

## How to apply
```bash
gcloud config set project ${YOUR PROJECT ID}

export TF_VAR_PROJECT_ID=YOUR_PROJECT_ID
export TF_VAR_ADMIN_USER=YOUR_GCP_ADMIN_USER
export TF_VAR_S3_DATA_PATH=YOUR_AWS_S3_CSV_FILE_PATH
export TF_VAR_S3_ACCESS_KEY_ID=YOUR_AWS_S3_ACCESS_KEY
export TF_VAR_S3_SECRET_ACCESS_KEY=YOUR_AWS_S3_SECRET_ACCESS_KEY
export TF_VAR_GCS_BUCKET_NAME=YOUR_GCS_BUCKET_NAME

terraform init
terraform plan
terraform apply
```


