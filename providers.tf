terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.gcp_credentials
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  credentials = var.gcp_credentials
}