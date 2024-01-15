# Create Storage Bucket
resource "google_storage_bucket" "remote_state" {
  name = var.bucket_name

  force_destroy = true
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_bucket.id
  }
}
