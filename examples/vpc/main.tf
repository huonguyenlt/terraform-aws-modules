provider "aws" {
  region = "ap-southeast-1"
}

module "vpc" {
  source = "../../vpc"

  name = "test-vpc"
  azs  = 2
}
