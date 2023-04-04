# Tencentcloud MultiversX Terraform Module

Terraform module which deploys a MultiversX observer node on Tencentcloud. It uses lighthouse.

Multiversx doc: https://github.com/multiversx/mx-chain-observing-squad#verify-the-running-containers

## Usage
```hcl
module "observer" {
  source        = "./modules/multiversx-observer"

  az            = "eu-frankfurt-1"

  instance_name = "mx-light"
  deployment_mode = "squad"
  observer_type   = "lite"
  purchase_period = 1
}
```

## Setting LightHouse instance
`bundle_id` is for instance type, and `blueprint_id` is for instance image. 

The optional values can be refered to here:
* https://www.tencentcloud.com/document/product/1103/42472
* https://www.tencentcloud.com/document/product/1103/42503

For other input variables, you can refer to:
* https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs/resources/lighthouse_instance

