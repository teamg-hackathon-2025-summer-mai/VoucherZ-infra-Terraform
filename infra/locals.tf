locals {
  public_azs  = toset([for _, v in var.public_subnets  : v.az])
  private_azs = toset([for _, v in var.private_subnets : v.az])
}

locals {
  ssm_param_paths = {
    DJANGO_ALLOWED_HOSTS = "/${var.project_prefix}/DJANGO_ALLOWED_HOSTS"
    DJANGO_ENV = "/${var.project_prefix}/DJANGO_ENV"
    DJANGO_SECRET_KEY = "/${var.project_prefix}/DJANGO_SECRET_KEY"
  }
}