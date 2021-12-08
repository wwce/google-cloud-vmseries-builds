# Google Cloud VM-Series Architecture Demos
## Overview
The purpose of this directory is to provide resources to quickly deploy and learn about various VM-Series architectures in Google Cloud.  The builds in this directory are completely independent of one another.  All of the builds use Terraform 1.0.x and use either the Google CLoud Terraform provider resources or the modules listed [here](https://github.com/wwce/google-cloud-vmseries-builds/tree/main/modules). 

## Architectures
Below is a summary of the builds to help you select the best architecture for your use-case.   A full deployment guide is included as part of the README.md in each build directory.

#### VM-Series Global VPC
This [build](https://github.com/wwce/google-cloud-vmseries-builds/tree/main/architecture-labs/vmseries-global-vpc) provides guideance on how to use Google Cloud network tags to steer outbound traffic to internal TCP/UDP load balancers that frontend regionally distributed VM-Series firewalls.  

![alt_text](vmseries-global-vpc/images/image1.png "image_tooltip")

## Support Policy
This solution is released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself.
