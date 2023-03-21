module "observer" {
  source        = "./modules/multiversx-observer"
  az            = "eu-frankfurt-1"
  instance_name = "mx-light"
  deployment_mode = "single"
  observer_type   = "lite"
  purchase_period = 1
}
