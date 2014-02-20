Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[nova-network]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile


Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========
This cookbook configures the networking required for OpenStack, specifically for the compute service nova.

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use)

Platform
--------

* CentOS >= 6.3
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* mysql
* nova
* osops-utils
* sysctl

Attributes
==========

Nova Networking
----
* `nova["network"]["provider"]` - The networking provider to use with nova. By default this is set to nova, but can be changed to quantum.
* `nova["networks"]` - An array of networks to be assigned to instances on creation

### Example
    [
        {
            "label" => "public",
            "ipv4_cidr" => "192.168.100.0/24",
            "bridge" => "br100",
            "bridge_dev" => "eth2",
            "dns1" => "8.8.8.8",
            "dns2" => "8.8.4.4"
        },
        {
            "label" => "private",
            "ipv4_cidr" => "192.168.200.0/24",
            "bridge" => "br200",
            "bridge_dev" => "eth3",
            "dns1" => "8.8.8.8",
            "dns2" => "8.8.4.4"
        }
    ]

* `nova["network"]["public_interface"]` - Interface for public IPs
* `nova["network"]["dmz_cidr"]` - A dmz range that should be accepted
* `nova["network"]["network_manager"]` - Class name for network manager
* `nova["network"]["dhcp_domain"]` - Domain to use for building hostnames
* `nova["network"]["force_dhcp_release"]` - Send DHCP release on instance termination?
* `nova["network"]["send_arp_for_ha"]` - Send gratuitous ARPs for HA setup?
* `nova["network"]["auto_assign_floating_ip"]` - Auto-assigning floating ip to VM?
* `nova["network"]["floating_pool_name"]` - if creating a floating ip pool, what to name it
* `nova["network"]["multi_host"]` - Use multi-host mode?
* `nova["network"]["platform"]` - Hash of platform specific package/service names and options

Quantum Networking
----
* `quantum["network_api_class"]` - used in nova.conf.the quantum api driver class. 
* `quantum["auth_strategy"]` - used in nova.conf. the authentication strategy to use, by default this is set to keystone
* `quantum["libvirt_vif_driver"]`- used in nova.conf. the virtual interface driver, by default nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
* `quantum["linuxnet_interface_driver"]` - used in nova.conf. the linux net interface driver, by default nova.network.linux_net.LinuxOVSInterfaceDriver
* `quantum["firewall_driver"]` - used in nova.conf. the firewall driver to use, by default nova.virt.libvirt.firewall.IptablesFirewallDriver
* `quantum["agent_down_time"]` - Seconds elapsed until an agent is considered down
* `quantum["services"]["api"]["scheme"]` - scheme for service (http/https)
* `quantum["services"]["api"]["network"]` - `osops_networks` network name which service operates on
* `quantum["services"]["api"]["port"]` - port service binds to
* `quantum["services"]["api"]["path"]` - service URI
* `quantum["services"]["api"]["cert_override"]` - for https - specify a custom certificate file location
* `quantum["services"]["api"]["key_override"]` - for https - specify a custom key file location
* `quantum["db"]["name"]` - database name
* `quantum["db"]["username"]` - database username
* `quantum["db"]["service_tenant_name"]` - defaults to `service`
* `quantum["db"]["service_user"]` - defaults to `quantum`
* `quantum["db"]["service_role"]` - defaults to `admin`
* `quantum["database"]["sqlalchemy_pool_size"]` - defaults to 5
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
* `quantum["dhcp_domain"] - Domain to use for instance host names`
* `quantum["ovs"]["provider_networks"]` - an Array of provider networks to create. Example:

```javascript
[
  {
    "label" => "ph-eth1",
    "bridge" => "br-eth1",
    "vlans" => "1:1000"
  },
  {
    "label" => "ph-eth0",
    "bridge" => "br-eth0",
    "vlans" => "1001:1024"
  }
]
```

Usage
=====
The recipes nova-controller and nova-compute are used in their corresponding roles single-controller and single-compute. The role quantum-network-manager has been added to indicate a node that is running l3_agent, dhcp_agent, and ovs_plugin.

Networks LWRP
=============
The nova-network cookbook has a resource and provider named networks. This LWRP provides the ability to create a fixed network, delete a fixed network, create a floating ip network, and delete a floating ip network.

Usage
-----

### Create a fixed network
    nova_network_networks "Create #{label}" do
        label label
        multi_host T|F
        fixed_range cidr
        bridge host bridge name (i.e. br100)
        bridge_int host bridge interface (i.e. eth0)
        dns1 primary dns server ip or name
        dns2 secondary dns server ip or name
        action :create_fixed
    end

### Delete a fixed_network
    nova_network_networks "Delete #{label}" do
        fixed_range cidr
        action :delete_fixed
    end

### Create a floating ip network
    nova_network_networks "Create floating ip network #{cidr}" do
        pool floating_pool_name
        float_range cidr
        action :create_floating
    end

### Delete a floating ip network
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
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)  

Copyright 2012-2013, Rackspace US, Inc.  

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
