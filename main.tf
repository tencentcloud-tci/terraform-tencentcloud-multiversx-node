locals {
  run_node_file   = var.deployment_mode == "single" ? "/run-node.sh" : "/squad-run-node.sh"
  cloud_disk_type = var.observer_type == "db-lookup-hdd" ? "CLOUD_PREMIUM" : "CLOUD_SSD"
  need_cloud_disk = contains(["db-lookup-hdd", "db-lookup-ssd"], var.observer_type) ? 1 : 0
}

data "external" "env" {
  program = ["${path.module}/env.sh"]
}

resource "tencentcloud_tat_command" "node-runner" {
  command_name      = "multiversx-node-runner"
  content           = file(join("", [path.module, local.run_node_file]))
  description       = "run node observer"
  command_type      = "SHELL"
  timeout           = 14400
  username          = "root"
  working_directory = "/root"
  enable_parameter  = true
}

resource "tencentcloud_tat_command" "node-tool" {
  command_name      = "multiversx-node-tool"
  content           = file(join("", [path.module, "/squad-node-tool.sh"]))
  description       = "node tool, you can use it to upgrade, start, stop and restart service"
  command_type      = "SHELL"
  timeout           = 3600
  username          = "root"
  working_directory = "/root"
  enable_parameter  = true
}

resource "tencentcloud_lighthouse_instance" "lighthouse" {
  bundle_id    = var.bundle_id
  blueprint_id = var.blueprint_id

  period     = var.purchase_period
  renew_flag = var.renew_flag

  instance_name = var.instance_name
  zone          = var.az

  # to wait for the TAT agent installation
  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "tencentcloud_lighthouse_disk" "cbs-0" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-0"
  disk_type = local.cloud_disk_type
  disk_size = 250
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
resource "tencentcloud_lighthouse_disk_attachment" "attach-0" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs-0[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_lighthouse_disk" "cbs-1" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-1"
  disk_type = local.cloud_disk_type
  disk_size = 350
  disk_charge_prepaid {
    period     = var.purchase_period
    renew_flag = var.renew_flag
    time_unit  = "m"
  }
  depends_on = [tencentcloud_lighthouse_instance.lighthouse]
}

resource "tencentcloud_lighthouse_disk_attachment" "attach-1" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs-1[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_lighthouse_disk" "cbs-2" {
  count     = local.need_cloud_disk
  zone      = var.az
  disk_name = "cbs-2"
  disk_type = local.cloud_disk_type
  disk_size = 150
  disk_charge_prepaid {
    period     = var.purchase_period
    renew_flag = var.renew_flag
    time_unit  = "m"
  }
  depends_on = [tencentcloud_lighthouse_instance.lighthouse]
}

resource "tencentcloud_lighthouse_disk_attachment" "attach-2" {
  count       = local.need_cloud_disk
  disk_id     = tencentcloud_lighthouse_disk.cbs-2[0].id
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id
}

resource "tencentcloud_lighthouse_firewall_rule" "firewall_rule" {
  instance_id = tencentcloud_lighthouse_instance.lighthouse.id

  dynamic "firewall_rules" {
    for_each = var.firewall_rules
    content {
      protocol                  = lookup(firewall_rules.value, "protocol", "TCP")
      port                      = lookup(firewall_rules.value, "port", "80")
      cidr_block                = lookup(firewall_rules.value, "cidr_block", "0.0.0.0/0")
      action                    = lookup(firewall_rules.value, "action", "DROP")
      firewall_rule_description = lookup(firewall_rules.value, "firewall_rule_description", "")
    }
  }
}

resource "tencentcloud_tat_invoker" "run" {
  name         = "start lite node"
  type         = "SCHEDULE"
  command_id   = tencentcloud_tat_command.node-runner.id
  instance_ids = [tencentcloud_lighthouse_instance.lighthouse.id, ]
  username     = "root"
  parameters = var.deployment_mode == "single" ? jsonencode({
    observer_type = var.observer_type
    secret_id     = data.external.env.result["TENCENTCLOUD_SECRET_ID"]
    secret_key    = data.external.env.result["TENCENTCLOUD_SECRET_KEY"]
    lighthouse_id = resource.tencentcloud_lighthouse_instance.lighthouse.id
    cbs_0         = ""
    cbs_1         = ""
    cbs_2         = ""
    cbs_float     = ""
    }) : jsonencode({
    observer_type = var.observer_type
    secret_id     = data.external.env.result["TENCENTCLOUD_SECRET_ID"]
    secret_key    = data.external.env.result["TENCENTCLOUD_SECRET_KEY"]
    lighthouse_id = resource.tencentcloud_lighthouse_instance.lighthouse.id
    cbs_0         = resource.tencentcloud_lighthouse_disk.cbs-0[0].id
    cbs_1         = resource.tencentcloud_lighthouse_disk.cbs-1[0].id
    cbs_2         = resource.tencentcloud_lighthouse_disk.cbs-2[0].id
    cbs_float     = var.floating_cbs
  })
  schedule_settings {
    policy      = "ONCE"
    invoke_time = timeadd(timestamp(), "10s")
  }
  depends_on = [
    tencentcloud_lighthouse_firewall_rule.firewall_rule,
    tencentcloud_lighthouse_disk_attachment.attach-0,
    tencentcloud_lighthouse_disk_attachment.attach-1,
    tencentcloud_lighthouse_disk_attachment.attach-2
  ]
}
