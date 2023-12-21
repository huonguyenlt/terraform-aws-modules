provider "aws" {
  region = "ap-southeast-1"
}

module "vpc" {
  source = "../../ecs-alb"
}
