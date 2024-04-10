terraform {
  required_version = ">=1.5"
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">= 1.81.32"
    }
    external = {
      source  = "hashicorp/external"
      version = ">=2.3.1"
    }
  }
}
