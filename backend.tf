terraform {
  cloud {
    organization = "kdieu-cloud"
    hostname     = "app.terraform.io"

    workspaces {
      name = "cloud-resume"
    }
  }
}