variable "instance_name" {
  type        = string
  description = "The name of the Lighthouse instance"
}

variable "az" {
  type        = string
  description = "The Availability Zone within the region"
}

variable "deployment_mode" {
  type        = string
  description = "Deployment mode"
  default     = "squad"
  validation {
    condition     = contains(["squad", "single"], var.deployment_mode)
    error_message = "Please choose one of the following deployment modes: single, squad."
  }
}

variable "observer_type" {
  type        = string
  description = "Observer node type"
  default     = "lite"
  validation {
    condition     = contains(["lite", "db-lookup-hdd", "db-lookup-ssd"], var.observer_type)
    error_message = "Please choose one of the following node types: lite, db-lookup-hdd, db-lookup-ssd"
  }
}

variable "bundle_id" {
  type        = string
  description = "Lighthouse bundle id"
  default     = "bundle_ent_lin_02"
}

variable "blueprint_id" {
  type        = string
  description = "Lighthouse blueprint id"
  default     = "lhbp-2rkazhl3" # docker-ubuntu20
}

variable "purchase_period" {
  type        = number
  description = "Purchase period"
  validation {
    condition     = contains([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 24, 36, 48, 60], var.purchase_period)
    error_message = "Please choose one of the following: 1,2,3,4,5,6,7,8,9,10,11,12,24,36,48,60"
  }
}

variable "renew_flag" {
  type        = string
  description = "Auto-Renewal flag"
  default     = "NOTIFY_AND_MANUAL_RENEW"
  validation {
    condition     = contains(["NOTIFY_AND_AUTO_RENEW", "NOTIFY_AND_MANUAL_RENEW", "DISABLE_NOTIFY_AND_AUTO_RENEW"], var.renew_flag)
    error_message = "Please choose one of the following: NOTIFY_AND_AUTO_RENEW, NOTIFY_AND_MANUAL_RENEW, DISABLE_NOTIFY_AND_AUTO_RENEW"
  }
}

variable "firewall_rules" {
  type = list(object({
    protocol                  = string
    port                      = string
    cidr_block                = string
    action                    = string
    firewall_rule_description = string
  }))
  description = "Firewall rules"
  default = [{
    "protocol"                  = "TCP"
    "port"                      = "37373,38383"
    "cidr_block"                = "0.0.0.0/0"
    "action"                    = "ACCEPT"
    "firewall_rule_description" = "ports required by nodes"
    },
    {
      "protocol"                  = "TCP"
      "port"                      = "22"
      "cidr_block"                = "172.10.1.0/24"
      "action"                    = "ACCEPT"
      "firewall_rule_description" = "ssh port"
  }]
}

variable "floating_cbs" {
  type        = string
  description = "CBS instance for deployment"
  default     = ""
}
