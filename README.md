Description
===========
This cookbook configures the networking required for OpenStack, specifically for the compute service nova.

Requirements
============

Attributes
==========
* `nova["network"]["provider"]` - The networking provider to use with nova. By default this is set to nova, but can be changed to quantum.

Nova Networking Attributes
* `nova["network"]["public"]["label"]` - Network label to be assigned to the public network on creation
* `nova["network"]["public"]["ipv4_cidr"]` - Network to be created (in CIDR notation, e.g., 192.168.100.0/24)
* `nova["network"]["public"]["num_networks"]` - Number of networks to be created
* `nova["network"]["public"]["network_size"]` - Number of IP addresses to be used in this network
* `nova["network"]["public"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br100)
* `nova["network"]["public"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth2)
* `nova["network"]["public"]["dns1"]` - DNS server 1
* `nova["network"]["public"]["dns2"]` - DNS server 2
* `nova["network"]["private"]["label"]` - Network label to be assigned to the private network on creation
* `nova["network"]["private"]["ipv4_cidr"]` - Network to be created (in CIDR notation e.g., 192.168.200.0/24)
* `nova["network"]["private"]["num_networks"]` - Number of networks to be created
* `nova["network"]["private"]["network_size"]` - Number of IP addresses to be used in this network
* `nova["network"]["private"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br200)
* `nova["network"]["private"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth3)
* `nova["network"]["floating_pool_name"]` - if creating a floating ip pool, what to name it

Quantum Networking Attributes
* `quantum["network_api_class"]` - used in nova.conf.the quantum api driver class. 
* `quantum["auth_strategy"]` - used in nova.conf. the authentication strategy to use, by default this is set to keystone
* `quantum["libvirt_vif_driver"]`- used in nova.conf. the virtual interface driver, by default nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
* `quantum["linuxnet_interface_driver"]` - used in nova.conf. the linux net interface driver, by default nova.network.linux_net.LinuxOVSInterfaceDriver
* `quantum["firewall_driver"]` - used in nova.conf. the firewall driver to use, by default nova.virt.libvirt.firewall.IptablesFirewallDriver
* `quantum["debug"]` - default log level is INFO
* `quantum["verbose"]` - default log level is INFO
* `quantum["overlap_ips"]` - Enable or disable overlapping IPs for subnets. MUST be set to False if Quantum is being used in conjunction with nova security groups and/or metadata service.
* `quantum["use_namespaces"]` - should correspond to overlap_ips used for dhcp agent and l3 agent.
* `quantum["plugin"]` - select the quantum backend driver plugin to use, currently only supports openvswitch
* `quantum["l3"]["router_id"]` - once a default network and router are created update the environment with the router uuid
* `quantum["l3"]["gateway_external_net_id"]` - once a default network and router are created update the environment with the external network uuid
* `quantum["ovs"]["network_type"]` - used to select the network type, currently only supports gre tunnels.
* `quantum["ovs"]["tunneling"]` - must be true if using GRE
* `quantum["ovs"]["tunnel_ranges"]` - Enumerating ranges of GRE tunnel ID
* `quantum["ovs"]["tunnel_bridge"]` - the tunnel interface name
* `quantum["ovs"]["external_bridge"]` - the external interface name
* `quantum["ovs"]["external_interface"]` - an available interface on the node that will access the external network

Usage
=====
The recipes nova-controller and nova-compute are used in their corresponding roles single-controller and single-compute. The role quantum-network-manager has been added to indicate a node that is running l3_agent, dhcp_agent, and ovs_plugin.

Networks LWRP
=============
The nova-network cookbook has a resource and provider named networks. This LWRP provides the ability to create a fixed network, delete a fixed network, create a floating ip network, and delete a floating ip network.

Usage:
To create a fixed network:
nova_network_networks "Create #{label}" do
    label label
    multi_host T|F
    fixed_range cidr
    num_networks number of networks
    net_size usable ip size
    bridge host bridge name (i.e. br100)
    bridge_int host bridge interface (i.e. eth0)
    dns1 primary dns server ip or name
    dns2 secondary dns server ip or name
    action :create_fixed
end

To Delete a fixed_network
nova_network_networks "Delete #{label}" do
    fixed_range cidr
    action :delete_fixed
end

To Create a floating ip network
nova_network_networks "Create floating ip network #{cidr}" do
    pool floating_pool_name
    float_range cidr
    action :create_floating
end

To Delete a floating ip network
nova_network_networks "Delete floating ip network #{cidr}" do
    float_range cidr
    action :delete_floating
end



License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Chris Laco (<chris.laco@rackspace.com>)

Copyright 2012, Rackspace US, Inc.  

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
