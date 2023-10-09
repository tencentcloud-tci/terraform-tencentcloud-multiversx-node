output "lighthouse_instance" {
  value       = tencentcloud_lighthouse_instance.lighthouse.id
  description = "lighthouse instance id"
}

output "tat_command_runner" {
  value       = var.need_tat_commands ? tencentcloud_tat_command.node_runner[0].id : data.tencentcloud_tat_command.command.command_set[0].command_id
  description = "TAT command id"
}