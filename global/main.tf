provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform-state" {
    bucket = "terraform-backend-state-lab"

    #prevent accidental deletion of the bucket
    lifecycle {
      prevent_destroy = true
    }
}

#enables versioning of s3 artifacts
resource "aws_s3_bucket_versioning" "terraform-state-versioning" {
    bucket = aws_s3_bucket.terraform-state.id
    versioning_configuration {
      status = "Enabled"
    }
}

#enables encryption on S3
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-state-bucket-encryption" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

#blocks public access to the bucket
resource "aws_s3_bucket_public_access_block" "terraform-state-access" {
  bucket = aws_s3_bucket.terraform-state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#DynamoDB table to lock the state
resource "aws_dynamodb_table" "terraform-state-locks" {
  name         = "terraform-backend-state-lab-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

#configures terraform backend to use S3
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-backend-state-lab"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-backend-state-lab-locks"
    encrypt        = true
  }
}