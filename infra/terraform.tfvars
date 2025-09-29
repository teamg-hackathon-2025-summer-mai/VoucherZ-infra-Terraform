project_prefix = "voucherz"
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  public_ap_northeast_1a = {
    az = "ap-northeast-1a"
    cidr = "10.0.0.0/26"
  }
  public_ap_northeast_1c = {
    az = "ap-northeast-1c"
    cidr = "10.0.0.64/26"
  }
}

private_subnets = {
  private_ap_northeast_1a_ecs = {
    az = "ap-northeast-1a"
    cidr = "10.0.0.128/27"
    role = "ecs"
  }
  private_ap_northeast_1a_rds = {
    az = "ap-northeast-1a"
    cidr = "10.0.0.192/28"
    role = "rds"
  }
  private_ap_northeast_1c_ecs = {
    az = "ap-northeast-1c"
    cidr = "10.0.0.160/27"
    role = "ecs"
  }
  private_ap_northeast_1c_rds = {
    az = "ap-northeast-1c"
    cidr = "10.0.0.208/28"
    role = "rds"
  }
}
