locals {
  run_node_file = var.deployment_mode == "single" ? "/run-node.sh" : "/squad-run-node.sh"
}

resource "tencentcloud_tat_command" "node-runner" {
  command_name      = "multiversx-node-runner"
  content           = file(join("", [path.module, local.run_node_file]))
  description       = "run node observer"
  command_type      = "SHELL"
  timeout           = 600
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
}

resource "tencentcloud_tat_invoker" "run" {
  name         = "start lite node"
  type         = "SCHEDULE"
  command_id   = tencentcloud_tat_command.node-runner.id
  instance_ids = [tencentcloud_lighthouse_instance.lighthouse.id, ]
  username     = "root"
  parameters = jsonencode({
    observer_type : var.observer_type
  })
  schedule_settings {
    policy      = "ONCE"
    invoke_time = timeadd(timestamp(), "10s")
  }
}
