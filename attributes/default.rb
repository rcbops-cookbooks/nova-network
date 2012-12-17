#
# Cookbook Name:: nova-network
# Attributes:: default
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO(shep): This should probably be ['nova']['network']['fixed']
default["nova"]["networks"] = [                                             # cluster_attribute
{
    "label" => "public",
    "ipv4_cidr" => "192.168.100.0/24",
    "num_networks" => "1",
    "network_size" => "255",
    "bridge" => "br100",
    "bridge_dev" => "eth2",
    "dns1" => "8.8.8.8",
    "dns2" => "8.8.4.4"
},
{
    "label" => "private",
    "ipv4_cidr" => "192.168.200.0/24",
    "num_networks" => "1",
    "network_size" => "255",
    "bridge" => "br200",
    "bridge_dev" => "eth3",
    "dns1" => "8.8.8.8",
    "dns2" => "8.8.4.4"
}
]

default["nova"]["network"]["public_interface"] = "eth0"                                        # node_attribute
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"                                       # cluster_attribute
default["nova"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"         # cluster_attribute
default["nova"]["network"]["dhcp_domain"] = "novalocal"                                        # cluster_attribute
default["nova"]["network"]["force_dhcp_release"] = true                                        # cluster_attribute
default["nova"]["network"]["send_arp_for_ha"] = true                                           # cluster_attribute
default["nova"]["network"]["auto_assign_floating_ip"] = false                                  # cluster_attribute
default["nova"]["network"]["floating_pool_name"] = "nova"                             # cluster_attribute
default["nova"]["network"]["multi_host"] = false

case platform
when "fedora", "redhat", "centos"
	default["nova-network"]["platform"]["essex-final"] = {
	  "nova_network_packages" => ["iptables", "openstack-nova-network"],
	  "nova_network_service" => "openstack-nova-network",
	  "common_packages" => ["openstack-nova-common"]
        }
	default["nova-network"]["platform"]["folsom"] = {
	  "nova_network_packages" => ["iptables", "openstack-nova-network"],
	  "nova_network_service" => "openstack-nova-network",
	  "common_packages" => ["openstack-nova-common", "python-cinderclient"]
	}
when "ubuntu"
	default["nova-network"]["platform"]["essex-final"] = {                                                   # node_attribute
          "nova_network_packages" => ["iptables", "nova-network"],
          "nova_network_service" => "nova-network",
	  "common_packages" => ["nova-common", "python-nova", "python-novaclient"]
	}
	default["nova-network"]["platform"]["folsom"] = {                                                   # node_attribute
          "nova_network_packages" => ["iptables", "nova-network"],
          "nova_network_service" => "nova-network",
	  "common_packages" => ["nova-common", "python-nova", "python-novaclient"]
	}
end

