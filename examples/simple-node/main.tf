module "observer" {
  source          = "git@github.com:ritch2022/terraform-tencentcloud-multiversx-lighthouse.git"
  az              = "eu-frankfurt-1"
  instance_name   = "mx-light"
  deployment_mode = "single"
  observer_type   = "lite"
  purchase_period = 1
}
