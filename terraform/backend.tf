# Partial backend configuration.
# Bucket and region are injected by the workflow via -backend-config flags:
#   terraform init \
#     -backend-config="bucket=$TF_STATE_BUCKET" \
#     -backend-config="region=$AWS_REGION"
#
# Run terraform/bootstrap first (via bootstrap.yml workflow) to create the
# bucket and DynamoDB table before using this backend.

terraform {
  backend "s3" {
    key            = "coova-chilli-builder/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
