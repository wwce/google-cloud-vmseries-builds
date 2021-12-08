
region                 = "us-east4"
project_id             = null
auth_file              = null
public_key_path        = "~/.ssh/gcp-demo.pub"
fw_service_account_name        = "paloaltonetworks-fw"
fw_image_uri           = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-flex-bundle1-1010"
fw_machine_type        = "n1-standard-4"


panorama_address        = "74.97.22.10"
panorama_device_group   = "gcp-autoscale"
panorama_template_stack = "gcp-autoscale_stack"
panorama_vm_auth_key       = "289932414614775"


mgmt_sources           = ["0.0.0.0/0"]
cidrs_mgmt              = "10.0.0.0/28"
cidrs_untrust           = "10.0.1.0/28"
cidrs_trust             = "10.0.2.0/28"
cidr_spoke1             = "10.1.0.0/28"
cidr_spoke2             = "10.2.0.0/28"
spoke_vm_image          = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/ubuntu-2004-lts-apache"
spoke_vm_type           = "f1-micro"
spoke_vm_user           = "paloalto"




extlb_healthcheck_port = 80

# Figure out notation
#autoscaler_metrics = = "custom.googleapis.com/VMSeries/panSessionActive" = = target = 100
    
