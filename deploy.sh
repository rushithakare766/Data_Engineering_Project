
PROJECT_ID="your-project-id"
BUCKET_NAME="your-bucket-name"
REGION="your-region"
FUNCTION_NAME="gcs_to_bigquery"
RUNTIME="python311"



BQ_DATASET="your_dataset"
BQ_TABLE="your_table"

# Set the project
echo "setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

#Enable required APIs 
echo "Enabling required APIs..." 


gcloud services enable cloudfunctions.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable storage.googleapis.com 

if gsutil ls -b gs://$BUCKET_NAME; then
    echo "Bucket $BUCKET_NAME already exists."
else
    echo "Creating bucket $BUCKET_NAME..."
    gsutil mb -l $REGION gs://$BUCKET_NAME
fi


echo "Creating BigQuery dataset and table..."
bq --location=$REGION mk -d $BQ_DATASET $PROJECT_ID:$BQ_DATASET || echo "Dataset $BQ_DATASET already exists." 


bq query --use_legacy_sql=false "CREATE TABLE IF NOT EXISTS \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\` 
(
id INT64,
 name STRING, 
 email STRING
)"

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

GCS_SERVICE_ACCOUNT=${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com

echo "Granting Pub/Sub Publisher role to $GCS_SERVICE_ACCOUNT..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:${GCS_SERVICE_ACCOUNT}" \
--role="roles/pubsub.publisher" \
--quiet

echo "Deploying Cloud Function $FUNCTION_NAME..."
gcloud functions deploy $FUNCTION_NAME \
--runtime $RUNTIME \
--trigger-resource $BUCKET_NAME \
--trigger-event google.storage.object.finalize \
--region $REGION \
--entry-point gcs_to_bigquery \
--source . \
--set-env-vars GCP_PROJECT=$PROJECT_ID,BQ_DATASET=$BQ_DATASET,BQ_TABLE=$BQ_TABLE \
--memory=256MB \
--timeout=60s \
--quiet 


echo "✅ Cloud Function deployed successfully!"

