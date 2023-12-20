
# ECS Cluster
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-cluster"
  tags = {
    Name = "${var.app_name}-ecs"
  }
}

# Public Load Balancer?

# Internal Load Balancer
