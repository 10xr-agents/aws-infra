aws_region          = "us-east-1"
project_name        = "10xr-ecs"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

services = [
  {
    name          = "cnvrs-srv"
    ecr_repo      = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/converse-server:0.0.1-demo"
    cpu           = 1024
    memory        = 2048
    desired_count = 2
    instance_type = "medium"
    port          = 8080
    health_check_path = "/actuator/health"
    environment_variables = {
      "ENV" = "demo"
      "SPRING_PROFILES_ACTIVE" = "demo"
    }
    secrets = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 3
        base              = 0
      },
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      }
    ]
  },
#   {
#     name          = "high-performance-service"
#     ecr_repo      = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/high-performance:latest"
#     cpu           = 4096
#     memory        = 8192
#     desired_count = 1
#     instance_type = "xlarge"
#     port          = 8080
#     health_check_path = "/status"
#     environment_variables = {
#       "ENV" = "production"
#     }
#     secrets = {}
#     additional_policies = []
#     capacity_provider_strategy = [
#       {
#         capacity_provider = "FARGATE"
#         weight            = 1
#         base              = 1
#       }
#     ]
#   }
]

instance_types = {
  "small"  = "t3.small"
  "medium" = "t3.medium"
  "large"  = "c5.large"
  "xlarge" = "c5.xlarge"
}

asg_min_size         = 1
asg_max_size         = 10
asg_desired_capacity = 1

ecs_cluster_settings = {
  containerInsights = "enabled"
}

enable_service_discovery = true
service_discovery_namespace = "10xr.internal"

enable_ecs_exec = true

mongodb_atlas_project_name="10xR"
mongodb_atlas_org_id="66837b4ad261004facc7fbac"
mongodb_atlas_project_id="66837b4ad261004facc7fbc7"
mongodb_atlas_region="US_EAST_1"
mongodb_atlas_cidr_block="192.168.248.0/21"
mongodb_database_name="converse-server"