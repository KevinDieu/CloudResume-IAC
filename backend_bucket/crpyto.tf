# Enable Cloud Storage service account to encrypt/decrypt Cloud KMS Keys
resource "google_project_iam_member" "kms_iam" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Create Encryption Keys
resource "google_kms_key_ring" "terraform_state" {
  name     = "${var.bucket_name}-keyring"
  location = "us"
}

resource "google_kms_crypto_key" "terraform_state_bucket" {
  name            = "${var.bucket_name}-key"
  key_ring        = google_kms_key_ring.terraform_state.id
  rotation_period = "7776000s"
}
