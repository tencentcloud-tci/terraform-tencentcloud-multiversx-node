output "lighthouse-instance" {
  value = tencentcloud_lighthouse_instance.lighthouse.id
}

output "TAT-command-runner" {
  value = var.need_tat_commands ? tencentcloud_tat_command.node-runner[0].id : data.tencentcloud_tat_command.command.command_set[0].command_id
}