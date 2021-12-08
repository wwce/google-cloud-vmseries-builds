output "FW_MGMT_ACCESS_REGION0" {
  value = { for k, v in module.vmseries_region0.nic1_ips : k => "${var.regions[0]} - https://${v}" }
}

output "FW_MGMT_ACCESS_REGION1" {
  value = { for k, v in module.vmseries_region1.nic1_ips : k => "${var.regions[1]} - https://${v}" }
}

output "SSH_TO_REGION0_VM" {
  value = { for k, v in module.vmseries_region0.nic0_ips : k => "${var.regions[0]} - ssh ${var.vm_user}@${v} -p 220" }
}

output "SSH_TO_REGION1_VM" {
  value = { for k, v in module.vmseries_region1.nic0_ips : k => "${var.regions[1]} - ssh ${var.vm_user}@${v} -p 221" }
}
