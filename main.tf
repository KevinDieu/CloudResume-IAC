# Project Configuration

data "google_billing_account" "billing_account" {
  billing_account = var.billing_account_id
}

import {
  to = module.gcp_project.module.project-factory.google_project.main
  id = "cloudresume-dieudonnetech"

}

module "gcp_project" {
  source          = "terraform-google-modules/project-factory/google"
  version         = "14.4.0"
  name            = var.project_id
  org_id          = var.org_id
  billing_account = data.google_billing_account.billing_account.id
  lien            = true

  activate_apis = [
    "compute.googleapis.com",        # Compute Engine API
    "container.googleapis.com",      # Kubernetes Engine API
    "iam.googleapis.com",            # Identity and Access Management (IAM) API
    "iamcredentials.googleapis.com", # IAM Service Account Credentials API
    "dns.googleapis.com",            # Cloud DNS API
    "monitoring.googleapis.com",     # Cloud Monitoring API
    "secretmanager.googleapis.com",  # Secret Manager API
    "cloudkms.googleapis.com",       # Cloud Key Management Service (KMS) API
  ]

}

# Service account
module "service_accounts" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.2.2"
  project_id   = var.project_id
  depends_on   = [module.gcp_project]
  names        = [var.gke_service_account_name]
  display_name = "GKE Service Account"
  description  = "Service account used to authenticate GKE worker nodes. Permissions are a superset of default Compute Engine storage account's and Storage Admin to mount Cloud Buckets"
  # Storage admin used for mounting Cloud Buckets as volumes
  project_roles = ["${var.project_id}=>roles/editor", "${var.project_id}=>roles/storage.admin"]

}



# GKE configuration
module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  version    = "~> 29.0.0"
  depends_on = [module.vpc, module.service_accounts, module.gcp_project]
  # Cluster Metadata
  count                   = var.cluster_count
  name                    = "${local.cluster_name}-01"
  project_id              = var.project_id
  cluster_resource_labels = var.labels
  # Cluster Config
  regional                   = false
  region                     = var.region
  zones                      = var.zones
  release_channel            = "RAPID"
  filestore_csi_driver       = true
  horizontal_pod_autoscaling = true
  create_service_account     = true
  deletion_protection        = false
  # service_account            = var.gke_service_account_name
  # Network
  network              = var.network_name
  subnetwork           = var.subnetwork
  ip_range_pods        = "${local.cluster_name}-pods"
  ip_range_services    = "${local.cluster_name}-services"
  cluster_dns_provider = "CLOUD_DNS"
  # Node pools
  remove_default_node_pool = true
  node_pools_labels = {
    spot-01 = {
      gke-spot = true
    },
  }
  node_pools_taints = {
    on-demand-01 = [
      {
        key    = "type"
        value  = "on-demand"
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }
  node_pools = [
    {
      name            = "on-demand-01"
      machine_type    = var.size
      min_count       = 0
      max_count       = 1
      local_ssd_count = 0
      spot            = false
      disk_size_gb    = 16
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      logging_variant = "DEFAULT"
      auto_repair     = true
      auto_upgrade    = true
      autoscaling     = true
      # service_account    = var.gke_service_account_name
      preemptible        = false
      initial_node_count = 0
    },
    {
      name            = "spot-01"
      machine_type    = var.size
      min_count       = 0
      max_count       = 1
      local_ssd_count = 0
      spot            = true
      disk_size_gb    = 16
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      logging_variant = "DEFAULT"
      auto_repair     = true
      auto_upgrade    = true
      autoscaling     = true
      # service_account    = var.gke_service_account_name
      preemptible        = false
      initial_node_count = 1
    }
  ]

}

# VPC Configuration
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 9.0.0"
  network_name = var.network_name
  project_id   = var.project_id
  depends_on   = [module.gcp_project]
  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/20"
      subnet_region = var.region
      description   = "Default Subnet"
    }
  ]
  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = "${local.cluster_name}-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "${local.cluster_name}-services"
        ip_cidr_range = "192.168.64.0/18"
      }
    ]
  }
}

# GCP Bucket Remote State

data "google_project" "project" {}

module "backend_bucket" {
  source = "./backend_bucket"
}

# Enable Cloud Storage service account to encrypt/decrypt Cloud KMS Keys
resource "google_project_iam_member" "kms_iam" {
  project = data.google_project.project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Create Encryption Keys
resource "google_kms_key_ring" "terraform_state" {
  name     = "${local.bucket_name}-keyring"
  location = "us"
}

resource "google_kms_crypto_key" "terraform_state_bucket" {
  name     = "${local.bucket_name}-key"
  key_ring = google_kms_key_ring.terraform_state.id
  rotation_period = 90
}

# Create Storage Bucket
resource "google_storage_bucket" "remote_state" {
  name          = local.bucket_name
  depends_on    = [module.gcp_project, google_project_iam_member.kms_iam]
  force_destroy = false
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_bucket.id
  }
}
