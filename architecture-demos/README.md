# Google Cloud VM-Series Architecture Demos
## Overview
The purpose of this directory is to provide resources to quickly deploy and learn about various VM-Series architectures in Google Cloud.  The builds in this directory are completely independent of one another.  All of the builds use Terraform 1.0.x and use either the Google CLoud Terraform provider resources or the modules listed [here](https://github.com/wwce/google-cloud-vmseries-builds/tree/main/modules). 

## Architectures
Below is a summary of the builds to help you select the best architecture for your use-case.   A full deployment guide is included as part of the README.md in each build directory.

### VM-Series Global VPC
This [build](https://github.com/wwce/google-cloud-vmseries-builds/tree/main/architecture-labs/vmseries-global-vpc) demonstrates how to use Google Cloud network tags to steer outbound traffic to internal TCP/UDP load balancers that frontend regionally distributed VM-Series firewalls.  


<p align="center">
    <img src="vmseries-global-vpc/images/image1.png" width="500">
</p>


### VM-Series Cloud IDS

This [build]() demonstrates how to use the VM-Series firewall and Google Cloud IDS to provide a layered security approach for a single VPC network.  VM-Series firewalls are positioned to provide north-south prevention controls and Cloud IDS provides intra-VPC (east/west) threat detection.

<p align="center">
    <img src="vmseries-cloud-ids/images/image1.png" width="500">
</p>

### VM-Series Hub and Spoke - Common Firewalls
This build demonstrates how to use a common set of VM-Series firewalls to secure internet inbound, internet outbound, and east-west traffic for a Google Cloud hub and spoke architecture.  This build focuses on how various traffic flows traverse through the VM-Series firewall (or hub) for Google peered VPC networks (or spokes).  You will also learn how to leverage Google Cloud network load balancers to provide horizontal scale and cross zonal redundancy to your own VM-Series deployments. 

<p align="center">
    <img src="vmseries-hub-spoke/images/image1.png" width="500">
</p>


### VM-Series Hub and Spoke - Autoscale
This build is the same as the **VM-Series Hub and Spoke - Common Firewalls**, except the VM-Series firewalls are deployed into a Google Cloud managed instance group.  The managed instance group provides the VM-Series the ability to automatically scale based on PAN-OS delievered metrics to Google StackDriver.  

**Note:  You will need a Panorama instance for this build**

<p align="center">
    <img src="vmseries-hub-spoke-autoscale/images/image1.png" width="500">
</p>


### VM-Series Hub and Spoke - Distributed Firewalls
This build is the same as the **VM-Series Hub and Spoke - Common Firewalls** except there are two pairs of VM-Series firewalls that are distributed to secure specific traffic flows.  In the build, a pair of VM-Series firewalls is dedicated to secure internet inbound traffic and the second pair is dedicatedd to handle all outbound internet and east/west traffic from the Spoke VPC networks. 

<p align="center">
    <img src="vmseries-hub-spoke-distributed/images/image1.png" width="500">
</p>

### VM-Series with Network Connectivity Center
This build uses Google Cloud Network Connectivity Center to provide full route propagation between a remote network and the VM-Series firewalls.  The build shows how to create BGP sessions with the Google cloud router to propagate routes to/from the remote netowrk and the VPC network's route table. 

<p align="center">
    <img src="vmseries-remote-network-ncc/images/image1.png" width="500">
</p>


### VM-Series with Cloud VPN
This build is the same as the **VM-Series Hub and Spoke - Common Firewalls** except we connect a remote network to a Cloud VPN gateway in Google Cloud.  The build demonstrates how to route and inspect the traffic with the VM-Series firewalls. 

<p align="center">
    <img src="vmseries-remote-network-cloud-vpn/images/image1.png" width="500">
</p>

## Support Policy
This solution is released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself.
