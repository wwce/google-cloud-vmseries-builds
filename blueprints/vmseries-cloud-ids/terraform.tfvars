
#project_id                = ""
#public_key_path           = "~/.ssh/gcp-demo.pub"
region                    = "us-east1"
subnet_cidrs              = ["192.168.0.0/24", "192.168.1.0/24", "192.168.11.0/24"]
service_scopes            = ["cloud-platform"]

#image_jenkins             = "https://www.googleapis.com/compute/v1/projects/panw-utd-public-cloud/global/images/utd-gcp-jenkins-server"
image_jenkins             = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/jenkins-11-2021"
image_kali                = "https://www.googleapis.com/compute/v1/projects/savvy-droplet-229621/global/images/kali37516s"
image_juice               = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/juice-shop-11-2021"
ip_jenkins                = "192.168.11.4"
ip_kali                   = "192.168.11.3"
ip_juice                  = "192.168.11.2"
ip_vmseries               = "192.168.11.5"

vmseries_bootstrap_bucket = "vmseries-bootstrap-ids-lab"
vmseries_image_url        = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/"
vmseries_image_name       = "vmseries-1013-bundle2-ids-lab" #"vmseries-flex-bundle2-1013"
vmseries_machine_type     = "n1-standard-4"
