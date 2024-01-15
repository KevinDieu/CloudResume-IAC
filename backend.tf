terraform {
  # backend "gcs" {
  #   bucket = "tfstate-cloudresume-dieudonnetech"
  #   prefix = "terraform/state"
  # }
  cloud {
    organization = "kdieu-cloud"
    hostname     = "app.terraform.io"

    workspaces {
      name = "cloud-resume"
    }
  }
}