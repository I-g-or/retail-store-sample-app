terraform {
  backend "s3" {
    bucket  = "retail-store-app-terraform-state-bucket"
    key     = "ecs/dev/terraform.tfstate"
    region  = "il-central-1"
    encrypt = true
  }
}