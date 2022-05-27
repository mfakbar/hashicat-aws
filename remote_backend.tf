terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "tfc-aws-workshop"
    workspaces {
      name = "hashicat-aws"
    }
  }
}
