locals {
  run_node_file   = "/scripts/squad-run-node.sh"
  cloud_disk_type = var.deployment_mode == "db-lookup-hdd" ? "CLOUD_PREMIUM" : "CLOUD_SSD"
  need_cloud_disk = contains(["db-lookup-hdd", "db-lookup-ssd"], var.deployment_mode) ? 1 : 0
  need_tat        = var.need_tat_commands ? 1 : 0
}

data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

data "tencentcloud_tat_command" "command" {
  command_type = "SHELL"
  created_by   = "USER"
  command_name = "multiversx-node-runner"
  lifecycle {
    postcondition {
      condition     = anytrue([!var.need_tat_commands && self.command_set != null, var.need_tat_commands])
      error_message = "Please check the TAT command, there is no required TAT command"
    }
  }
}

resource "tencentcloud_tat_command" "node_runner" {
  count             = local.need_tat
  command_name      = "multiversx-node-runner"
  content           = file(join("", [path.module, local.run_node_file]))
  description       = "run node observer"
  command_type      = "SHELL"
  timeout           = 14400
  username          = "root"
  working_directory = "/root"
  enable_parameter  = true
  default_parameters = jsonencode({
    "lighthouse_id" : "",
    "network" : "",
    "deployment_mode" : "",
    "secret_id" : "",
    "secret_key" : "",
    "cbs_0" : "",
    "cbs_1" : "",
    "cbs_2" : "",
    "cbs_float" : ""
  })
}

resource "tencentcloud_tat_command" "node_tool" {
  count             = local.need_tat
  command_name      = "multiversx-node-tool"
  content           = file(join("", [path.module, "/scripts/squad-node-tool.sh"]))
  description       = "An efficient process tool, you can use it for upgrading, starting, stopping or restarting the node services"
  command_type      = "SHELL"
  timeout           = 3600
  username          = "root"
  working_directory = "/root"
  enable_parameter  = true
  default_parameters = jsonencode({
    "command" : ""
  })
}

resource "tencentcloud_lighthouse_firewall_template" "firewall_template" {
  template_name = "MultiversX-firewall-template"

  template_rules {
    protocol                  = "TCP"
    port                      = "37373-38383"
    cidr_block                = "0.0.0.0/0"
    action                    = "ACCEPT"
    firewall_rule_description = "ports required by node"
  }

  template_rules {
    protocol                  = "UDP"
    port                      = "123"
    cidr_block                = "0.0.0.0/0"
    action                    = "ACCEPT"
    firewall_rule_description = "port required by the NTP service"
  }

  template_rules {
    protocol                  = "TCP"
    port                      = "22"
    cidr_block                = var.ssh_client_cidr
    action                    = "ACCEPT"
    firewall_rule_description = "ssh port"
  }

  dynamic "template_rules" {
    for_each = var.extra_firewall_rules
    content {
      protocol                  = lookup(template_rules.value, "protocol", "")
      port                      = lookup(template_rules.value, "port", "")
      cidr_block                = lookup(template_rules.value, "cidr_block", "")
      action                    = lookup(template_rules.value, "action", "")
      firewall_rule_description = lookup(template_rules.value, "firewall_rule_description", "")
    }
  }
}

resource "tencentcloud_lighthouse_instance" "lighthouse" {
  bundle_id    = var.bundle_id
  blueprint_id = var.blueprint_id

  period     = var.purchase_period
  renew_flag = var.renew_flag

  instance_name = var.instance_name
  zone          = var.az

  firewall_template_id = tencentcloud_lighthouse_firewall_template.firewall_template.id

  # waiting for the TAT agent installation
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "tencentcloud_lighthouse_disk" "cbs_0" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-0"
  disk_type = local.cloud_disk_type
  disk_size = var.cbs0_disk_size
  disk_charge_prepaid {
    period     = var.purchase_period
    renew_flag = var.renew_flag
    time_unit  = "m"
  }
  depends_on = [tencentcloud_lighthouse_instance.lighthouse]
}

# why we use attachment not auto_mount_configuration when creating cloud disk?
# to make it possible to do terraform destroy, when destroy disk it must be dettached.
# bad design here.
resource "tencentcloud_lighthouse_disk_attachment" "attach_0" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs_0[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_lighthouse_disk" "cbs_1" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-1"
  disk_type = local.cloud_disk_type
  disk_size = var.cbs1_disk_size
  disk_charge_prepaid {
    period     = var.purchase_period
    renew_flag = var.renew_flag
    time_unit  = "m"
  }
  depends_on = [tencentcloud_lighthouse_instance.lighthouse]
}

resource "tencentcloud_lighthouse_disk_attachment" "attach_1" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs_1[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_lighthouse_disk" "cbs_2" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-2"
  disk_type = local.cloud_disk_type
  disk_size = var.cbs2_disk_size
  disk_charge_prepaid {
    period     = var.purchase_period
    renew_flag = var.renew_flag
    time_unit  = "m"
  }
  depends_on = [tencentcloud_lighthouse_instance.lighthouse]
}

resource "tencentcloud_lighthouse_disk_attachment" "attach_2" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs_2[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_tat_invocation_invoke_attachment" "run" {
  command_id  = var.need_tat_commands ? tencentcloud_tat_command.node_runner[0].id : data.tencentcloud_tat_command.command.command_set[0].command_id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
  username    = "root"
  parameters = var.deployment_mode == "lite" ? jsonencode({
    deployment_mode = var.deployment_mode
    secret_id       = data.external.env.result["TENCENTCLOUD_SECRET_ID"]
    secret_key      = data.external.env.result["TENCENTCLOUD_SECRET_KEY"]
    lighthouse_id   = resource.tencentcloud_lighthouse_instance.lighthouse.id
    cbs_0           = ""
    cbs_1           = ""
    cbs_2           = ""
    cbs_float       = ""
    network         = var.network
    }) : jsonencode({
    deployment_mode = var.deployment_mode
    secret_id       = data.external.env.result["TENCENTCLOUD_SECRET_ID"]
    secret_key      = data.external.env.result["TENCENTCLOUD_SECRET_KEY"]
    lighthouse_id   = resource.tencentcloud_lighthouse_instance.lighthouse.id
    cbs_0           = resource.tencentcloud_lighthouse_disk.cbs_0[0].id
    cbs_1           = resource.tencentcloud_lighthouse_disk.cbs_1[0].id
    cbs_2           = resource.tencentcloud_lighthouse_disk.cbs_2[0].id
    cbs_float       = var.floating_cbs
    network         = var.network
  })
  timeout = 14400

  depends_on = [
    tencentcloud_lighthouse_disk_attachment.attach_0,
    tencentcloud_lighthouse_disk_attachment.attach_1,
    tencentcloud_lighthouse_disk_attachment.attach_2
  ]
}
