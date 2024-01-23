variable "gcp_credentials" {
  type        = string
  sensitive   = true
  description = "Google Cloud service account credentials"
}

variable "org_id" {
  type        = string
  description = "ID of target GCP Organization"
}

variable "project_id" {
  type        = string
  description = "ID of target GCP Project"
}

variable "billing_account_id" {
  type        = string
  sensitive   = true
  description = "ID of billing account to use for project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Target GCP Compute Region for resource deployment"
}

variable "zones" {
  type        = list(string)
  default     = ["us-central1-c"]
  description = "Target GCP CE Zones for resource deployment"
}

variable "size" {
  type        = string
  default     = "e2-standard-2"
  description = "Default Size for CE instances"
}

variable "cluster_count" {
  type        = number
  default     = 1
  description = "Number of GKE Clusters to create"

  validation {
    condition = var.cluster_count <= 3
    error_message = "Cluster count cannot be higher than 3"
  }
}

variable "network_name" {
  type        = string
  description = "Name of managed VPC Network"
}

variable "subnetwork" {
  type        = string
  default     = "subnet-01"
  description = "Name of created VPC Subnet"
}

variable "labels" {
  type = map(string)
  default = {
    application = "cloudresume"
  }
  description = "Standard set of labels to apply to resources"
}

variable "gke_service_account_name" {
  type        = string
  default     = "gke-serviceaccount"
  description = "Name of Service Account to use for GKE node pool operations"
}
