project_id              = "host-4502127"
public_key_path         = "~/.ssh/gcp-demo.pub"
region                  = "us-east4"
fw_image_name           = "vmseries-bundle2-909"
fw_machine_type         = "n1-standard-4"

mgmt_sources            = ["0.0.0.0/0"]
cidr_mgmt               = "192.168.0.0/28"
cidr_untrust            = "192.168.1.0/28"
cidr_trust              = "192.168.2.0/28"