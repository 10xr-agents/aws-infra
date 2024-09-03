aws_region          = "us-east-1"
project_name        = "my-ecs-project"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

services = [
  {
    name          = "service1"
    ecr_repo      = "your-account-id.dkr.ecr.us-west-2.amazonaws.com/service1"
    cpu           = 256
    memory        = 512
    desired_count = 2
    compute_type  = "on_demand"
  },
  {
    name          = "service2"
    ecr_repo      = "your-account-id.dkr.ecr.us-west-2.amazonaws.com/service2"
    cpu           = 256
    memory        = 512
    desired_count = 2
    compute_type  = "on_demand"
  },
  {
    name          = "service3"
    ecr_repo      = "your-account-id.dkr.ecr.us-west-2.amazonaws.com/service3"
    cpu           = 512
    memory        = 1024
    desired_count = 2
    compute_type  = "spot"
  },
  {
    name          = "service4"
    ecr_repo      = "your-account-id.dkr.ecr.us-west-2.amazonaws.com/service4"
    cpu           = 256
    memory        = 512
    desired_count = 2
    compute_type  = "on_demand"
  },
  {
    name          = "service5"
    ecr_repo      = "your-account-id.dkr.ecr.us-west-2.amazonaws.com/service5"
    cpu           = 256
    memory        = 512
    desired_count = 2
    compute_type  = "on_demand"
  }
]

instance_type_on_demand = "t3.medium"
instance_type_spot      = "t3.small"

asg_on_demand_min_size         = 1
asg_on_demand_max_size         = 5
asg_on_demand_desired_capacity = 3

asg_spot_min_size         = 1
asg_spot_max_size         = 5
asg_spot_desired_capacity = 2