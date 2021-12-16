#panorama_address        = ""
#panorama_device_group   = ""
#panorama_template_stack = ""
#panorama_vm_auth_key    = ""

project_id              = null
public_key_path         = "~/.ssh/gcp-demo.pub"
region                  = "us-east4"
fw_image_uri            = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-flex-bundle1-1010"
fw_service_account_name = "paloaltonetworks-fw"
fw_machine_type         = "n1-standard-4"

mgmt_sources            = ["0.0.0.0/0"]
cidrs_mgmt              = "10.0.0.0/28"
cidrs_untrust           = "10.0.1.0/28"
cidrs_trust             = "10.0.2.0/28"
cidr_spoke1             = "10.1.0.0/28"
cidr_spoke2             = "10.2.0.0/28"
spoke_vm_image          = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/ubuntu-2004-lts-apache"
spoke_vm_type           = "f1-micro"
spoke_vm_user           = "paloalto"
extlb_healthcheck_port  = 80

auth_file               = null