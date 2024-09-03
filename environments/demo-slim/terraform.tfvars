aws_region          = "us-east-1"
project_name        = "10xr-ecs"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

services = [
  {
    name          = "cnvrs-srv"
    ecr_repo      = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/converse-server:0.0.1-demo"
    cpu           = 1000
    memory        = 2048
    desired_count = 2
    compute_type  = "on_demand"
    port          = 80
    health_check_path = "/health"
    environment_variables = {
      "ENV" = "production"
    }
    secrets = {
      # "DB_PASSWORD" = "arn:aws:ssm:us-east-1:your-account-id:parameter/service1/db-password"
    }
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  },
#   {
#     name          = "service2"
#     ecr_repo      = "your-account-id.dkr.ecr.us-east-1.amazonaws.com/service2"
#     cpu           = 256
#     memory        = 512
#     desired_count = 2
#     compute_type  = "on_demand"
#     port          = 8080
#     health_check_path = "/status"
#     environment_variables = {}
#     secrets = {}
#     additional_policies = []
#   },
  # ... other services
]

instance_type_on_demand = "t3.medium"
instance_type_spot      = "c5.2xlarge"

asg_on_demand_min_size         = 1
asg_on_demand_max_size         = 5
asg_on_demand_desired_capacity = 3

asg_spot_min_size         = 1
asg_spot_max_size         = 5
asg_spot_desired_capacity = 2

ecs_cluster_settings = {
  containerInsights = "enabled"
}

enable_service_discovery = true
service_discovery_namespace = "10xr.internal"

enable_ecs_exec = true