# Service account
module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = var.project_id
  names      = [var.gke_service_account_name]
  display_name = "GKE Service Account"
  description = "Service account used to authenticate GKE worker nodes. Permissions are a superset of default Compute Engine storage account's and Storage Admin to mount Cloud Buckets"
  # Storage admin used for mounting Cloud Buckets as volumes
  project_roles = ["${var.project_id}=>Editor", "${var.project_id}=>Storage Admin"]

}

locals {
  cluster_name = "cluster"
}

# GKE configuration
module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  version    = "~> 29.0.0"
  depends_on = [module.vpc]
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
  service_account            = google_service_account.gke_service_account.account_id
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
      name           = "on-demand-01"
      node_locations = var.zones
      machine_type   = var.size
      min_count      = 0
      max_count      = 1
      auto_upgrade   = true
      autoscaling    = true
      disk_size_gb   = 16
      disk_type      = "pd-standard"
      spot           = false
    },
    {
      name           = "spot-01"
      machine_type   = var.size
      node_locations = var.zones
      min_count      = 1
      max_count      = 1
      auto_upgrade   = true
      autoscaling    = true
      disk_size_gb   = 16
      disk_type      = "pd-standard"
      spot           = true
    }
  ]

}

# VPC Configuration
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 9.0.0"
  network_name = var.network_name
  project_id   = var.project_id
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
