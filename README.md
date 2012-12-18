Description
===========

Requirements
============

Attributes
==========
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

Usage
=====
* recipe[nova-network::network] - install required nova network services, usually run anywhere nova-compute is running.
* recipe[nova-network::setup] - create initial networks for nova
* networks LWRP - use to create networks inside of nova

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  

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
