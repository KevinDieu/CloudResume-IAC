terraform {
  backend "gcs" {
    bucket = "tfstate-cloudresume-dieudonnetech"
    prefix = "terraform/state"
  }
}