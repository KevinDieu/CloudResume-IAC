variable "org_id" {
  type = string
  description  = "ID of target GCP Organization"
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zones" {
  type    = list(string)
  default = ["us-central1-c"]
}

variable "size" {
  type    = string
  default = "e2-standard-2"
}

variable "cluster_count" {
  type    = number
  default = 1
}

variable "network_name" {
  type = string
}

variable "subnetwork" {
  type    = string
  default = "subnet-01"
}

variable "labels" {
  type = map()
  default = {
    env = var.project_id
    application = "cloudresume"
  }
}

variable "gke_service_account_name" {
  type = string
  default = "gke-serviceaccount"
}