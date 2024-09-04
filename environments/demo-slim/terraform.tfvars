aws_region          = "us-east-1"
project_name        = "10xr-ecs"
domain_name         = "10xr.co"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

services = [
  {
    name              = "cnvrs-srv"
    ecr_repo          = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/converse-server:0.0.1-demo"
    cpu               = 256
    memory            = 512
    desired_count     = 2
    instance_type     = "medium"
    port              = 8080
    health_check_path = "/actuator/health"
    environment_variables = {
      "ENV"                    = "demo"
      "ECS_ENVIRONMENT"        = "demo"
      "SPRING_PROFILES_ACTIVE" = "demo"
    }
    secrets             = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      }
    ]
  },
  {
    name              = "cnvrs-ui"
    ecr_repo          = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/converse-server:0.0.1-demo"
    cpu               = 512
    memory            = 1024
    desired_count     = 2
    instance_type     = "medium"
    port              = 3000
    health_check_path = "/app/api/management/health"
    environment_variables = {
      "ENV"                    = "demo"
      "ECS_ENVIRONMENT"        = "demo"
      "SPRING_PROFILES_ACTIVE" = "demo"
    }
    secrets             = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      }
    ]
  },
  {
    name              = "livkt-prxy"
    ecr_repo          = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/livekit-proxy:latest"
    cpu               = 512
    memory            = 1024
    desired_count     = 2
    instance_type     = "medium"
    port              = 9000
    health_check_path = "/api/v1/management/health"
    environment_variables = {
      "ENV"                    = "demo"
      "ECS_ENVIRONMENT"        = "demo"
      "SPRING_PROFILES_ACTIVE" = "demo"
    }
    secrets             = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      }
    ]
  },
  {
    name              = "cnvrs-agt"
    ecr_repo          = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/conversation-agent:v1.0.0-demo"
    cpu               = 2048
    memory            = 4096
    desired_count     = 2
    instance_type     = "medium"
    port              = 9600
    health_check_path = "/health"
    environment_variables = {
      "ENV"             = "demo"
      "ECS_ENVIRONMENT" = "demo"
    }
    secrets             = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      }
    ]
  },
  {
    name              = "agt-anlytc"
    ecr_repo          = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/agent-analytics:v1.0.0-demo"
    cpu               = 2048
    memory            = 4096
    desired_count     = 2
    instance_type     = "medium"
    port              = 9800
    health_check_path = "/management/health"
    environment_variables = {
      "ENV"             = "demo"
      "ECS_ENVIRONMENT" = "demo"
    }
    secrets             = {}
    additional_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 2
      }
    ]
  }
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

enable_service_discovery    = true
service_discovery_namespace = "10xr.internal"

enable_ecs_exec = true

mongodb_atlas_project_name = "10xR"
mongodb_atlas_org_id       = "66837b4ad261004facc7fbac"
mongodb_atlas_project_id   = "66837b4ad261004facc7fbc7"
mongodb_atlas_region       = "US_EAST_1"
mongodb_atlas_cidr_block   = "192.168.248.0/21"
mongodb_database_name      = "converse-server"

livekit_domain_name      = "livekit-demo.10xr.co"
livekit_turn_domain_name = "livekit-turn-demo.10xr.co"
livekit_api_key          = "livekit-demo-key"

cloudflare_api_token = "jTm01UhNhNDE-Md4jrQwBS0w3vHsqVikxC9cop9r"
cloudflare_zone_id   = "3ae048b26df2c81c175c609f802feafb"