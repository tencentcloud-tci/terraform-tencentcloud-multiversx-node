variable "instance_name" {
  type        = string
  description = "The name of the Lighthouse instance"
}

variable "az" {
  type        = string
  description = "The Availability Zone within the region"
}

variable "need_tat_commands" {
  type        = bool
  description = "If the TAT commands (multiversx-node-runner and multiversx-node-tool) need to be created"
  default     = true
}

variable "deployment_mode" {
  type        = string
  description = "Deployment mode"
  default     = "lite"
  validation {
    condition     = contains(["lite", "db-lookup-hdd", "db-lookup-ssd"], var.deployment_mode)
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
  default     = "lhbp-a7oxy3em" # docker-OCOS8
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

variable "ssh_client_cidr" {
  type        = string
  description = "SSH client cidr"
  validation {
    condition     = can(cidrhost(var.ssh_client_cidr, 0))
    error_message = "Must be valid IPv4 CIDR"
  }
}

variable "extra_firewall_rules" {
  type = list(object({
    protocol                  = string
    port                      = string
    cidr_block                = string
    action                    = string
    firewall_rule_description = string
  }))
  description = "Extra firewall rules"
  default     = []
}

variable "floating_cbs" {
  type        = string
  description = "CBS instance for deployment"
  default     = ""
}

variable "cbs0_disk_size" {
  type        = number
  description = "Size of the disk used to deploy node-0 and node-metachain"
  default     = 350
}

variable "cbs1_disk_size" {
  type        = number
  description = "Size of the disk used to deploy node-1"
  default     = 450
}

variable "cbs2_disk_size" {
  type        = number
  description = "Size of the disk used to deploy node-2"
  default     = 300
}

variable "network" {
  type        = string
  description = "Network"
  validation {
    condition     = contains(["mainnet", "testnet", "devnet"], var.network)
    error_message = "Please choose one of the following network: mainnet, testnet, devnet"
  }
}
