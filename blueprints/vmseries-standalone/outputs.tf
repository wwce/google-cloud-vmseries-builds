# --------------------------------------------------------------------------------------------------------------------------
# Outputs to terminal

output VMSERIES_WEB_ACCESS {
  value = "https://${module.vmseries.nic0_ips["vmseries01"]}"
}
output VMSERIES_SSH_ACCESS {
  value = "ssh admin@${module.vmseries.nic0_ips["vmseries01"]} -i ${replace(var.public_key_path, ".pub", "")}"
}