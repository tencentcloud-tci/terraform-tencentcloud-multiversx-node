variable "instance_name" {
  type        = string
  description = "The lighthouse instance name"
}

variable "az" {
  type        = string
  description = "Available zone"
}

variable "deployment_mode" {
  type        = string
  description = "Deployment mode"
  default     = "single"
  validation {
    condition     = contains(["squad", "single"], var.deployment_mode)
    error_message = "Valid value is one of the following: single, squad."
  }
}

variable "observer_type" {
  type        = string
  description = "Observer node type"
  default     = "lite"
  validation {
    condition     = contains(["lite"], var.observer_type)
    error_message = "Valid value is one of the following: lite"
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
  default     = "lhbp-2rkazhl3"
}

variable "purchase_period" {
  type = number
  description = "Purchase period"
  validation {
    condition = contains([1,2,3,4,5,6,7,8,9,10,11,12,24,36,48,60], var.purchase_period)
    error_message = "Valid value is one of the following: 1,2,3,4,5,6,7,8,9,10,11,12,24,36,48,60"
  }
}

variable "renew_flag" {
  type = string
  description = "Auto-Renewal flag"
  default = "NOTIFY_AND_MANUAL_RENEW"
  validation {
    condition = contains(["NOTIFY_AND_AUTO_RENEW", "NOTIFY_AND_MANUAL_RENEW", "DISABLE_NOTIFY_AND_AUTO_RENEW"], var.renew_flag)
    error_message = "Valid value is one of the following: NOTIFY_AND_AUTO_RENEW, NOTIFY_AND_MANUAL_RENEW, DISABLE_NOTIFY_AND_AUTO_RENEW"
  }
}
