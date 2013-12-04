#
# Cookbook Name:: nova-network
# Attributes:: default
#
# Copyright 2012-2013, Rackspace US, Inc.
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
default["nova"]["network"]["provider"] = "nova"

# ######################################################################### #
# Nova-Network Configuration Attributes
# ######################################################################### #
# TODO(shep): This should probably be ['nova']['network']['fixed']
default["nova"]["networks"]["public"] = {                                            # cluster_attribute
  "label" => "public",
  "ipv4_cidr" => "192.168.100.0/24",
  "bridge" => "br100",
  "bridge_dev" => "eth2",
  "dns1" => "8.8.8.8",
  "dns2" => "8.8.4.4"
}
# Specify other networks in the environment file, e.g:
#default["nova"]["networks"]["private"] = {
#  "label" => "private",
#  "ipv4_cidr" => "192.168.200.0/24",
#  "bridge" => "br200",
#  "bridge_dev" => "eth3",
#  "dns1" => "8.8.8.8",
#  "dns2" => "8.8.4.4"
#}

default["nova"]["network"]["public_interface"] = "eth0"                                        # node_attribute
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"                                       # cluster_attribute
default["nova"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"         # cluster_attribute
default["nova"]["network"]["dhcp_domain"] = "novalocal"                                        # cluster_attribute
default["nova"]["network"]["force_dhcp_release"] = true                                        # cluster_attribute
default["nova"]["network"]["send_arp_for_ha"] = true                                           # cluster_attribute
default["nova"]["network"]["auto_assign_floating_ip"] = false                                  # cluster_attribute
default["nova"]["network"]["floating_pool_name"] = "nova"                             # cluster_attribute
default["nova"]["network"]["multi_host"] = true
default["nova"]["network"]["dhcp_lease_time"] = 120
default["nova"]["network"]["fixed_ip_disassociate_timeout"] = 600

# ######################################################################### #
# RPCDaemon Configuration Attributes
# ######################################################################### #
# how long to sleep between L3/DHCP status checks
default["rpcdaemon"]["check_interval"] = 1
# x-expires settings for rabbit recv queues
default["rpcdaemon"]["queue_expire"] = 60
# quantum API timeouts
default["rpcdaemon"]["timeout"] = 20


# ######################################################################### #
# Quantum Configuration Attributes
# ######################################################################### #
# nova.conf options for quantum
default["quantum"]["network_api_class"] = "nova.network.quantumv2.api.API"
default["quantum"]["auth_strategy"] = "keystone"
default["quantum"]["libvirt_vif_type"] = "ethernet"
default["quantum"]["libvirt_vif_driver"] =
  "nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver"
default["quantum"]["linuxnet_interface_driver"] =
  "nova.network.linux_net.LinuxOVSInterfaceDriver"
default["quantum"]["firewall_driver"] =
  "nova.virt.firewall.NoopFirewallDriver"
default["quantum"]["notification_driver"] = "quantum.openstack.common.notifier.no_op_notifier"
default["quantum"]["security_group_api"] = "quantum"
default["quantum"]["isolated_metadata"] = "True"
default["quantum"]["service_quantum_metadata_proxy"] = "True"
default["quantum"]["agent_down_time"] = 30

default["quantum"]["services"]["api"]["scheme"] = "http"
default["quantum"]["services"]["api"]["network"] = "public"
default["quantum"]["services"]["api"]["port"] = 9696
default["quantum"]["services"]["api"]["path"] = ""
default["quantum"]["services"]["api"]["cert_file"] = "quantum.pem"
default["quantum"]["services"]["api"]["key_file"] = "quantum.key"
default["quantum"]["services"]["api"]["wsgi_file"] = "quantum-server"

default["quantum"]["db"]["name"] = "quantum"
default["quantum"]["db"]["username"] = "quantum"

default["quantum"]["service_tenant_name"] = "service"
default["quantum"]["service_user"] = "quantum"
default["quantum"]["service_role"] = "admin"
default["quantum"]["debug"] = "False"
default["quantum"]["verbose"] = "False"

default["quantum"]["overlap_ips"] = "True"
default["quantum"]["use_namespaces"] = "True" # should correspond to overlap_ips used for dhcp agent and l3 agent.

# Manage plugins here, currently only supports openvswitch (ovs)
default["quantum"]["plugin"] = "ovs"

# l3 agent placeholders
default["quantum"]["l3"]["router_id"] = ""
default["quantum"]["l3"]["gateway_external_net_id"] = ""

# dhcp agent options
default["quantum"]["dhcp_lease_time"] = "1440"
default["quantum"]["dhcp_domain"] = "openstacklocal"

# quantum.conf options
default["quantum"]["quota_items"] = "network,subnet,port"
default["quantum"]["default_quota"] = "-1"
default["quantum"]["quota_network"] = "10"
default["quantum"]["quota_subnet"] = "10"
default["quantum"]["quota_port"] = "50"
default["quantum"]["quota_driver"] = "quantum.db.quota_db.DbQuotaDriver"

# Plugin defaults
# OVS
default["quantum"]["ovs"]["network_type"] = "vlan"
default["quantum"]["ovs"]["tunnel_ranges"] = "1:1000"           # Enumerating ranges of GRE tunnel IDs that are available for tenant network allocation (if GRE)
default["quantum"]["ovs"]["integration_bridge"] = "br-int"      # Don't change without a good reason..
default["quantum"]["ovs"]["tunnel_bridge"] = "br-tun"           # only used if tunnel_ranges is set
default["quantum"]["ovs"]["external_bridge"] = "br-ex"
default["quantum"]["ovs"]["external_interface"] = "eth1"
default["quantum"]["ovs"]["network"]="nova"
default["quantum"]["ovs"]["firewall_driver"] =
  "quantum.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"

# Generic regex for process pattern matching (to be used as a base pattern).
# Works for both Grizzly and Havana packages on Ubuntu and CentOS.
procmatch_base = '^((/usr/bin/)?python\d? )?(/usr/bin/)?'

case platform
when "fedora", "redhat", "centos"

  # Array of all the provider based networks to create
  default["quantum"]["ovs"]["provider_networks"] = [
    {
      "label" => "ph-em2",
      "bridge" => "br-em2",
      "vlans" => "1:1000"
    }
  ]
  default["nova-network"]["platform"] = {
    "nova_network_packages" => ["iptables", "openstack-nova-network"],
    "nova_network_service" => "openstack-nova-network",
    "nova_network_procmatch" => procmatch_base + 'nova-network\b',
    "common_packages" => ["openstack-nova-common", "python-cinderclient"],
    "package_options" => ""
  }

  default["quantum"]["platform"] = {
    "epel_openstack_packages" => ["kernel", "iproute"],
    "mysql_python_packages" => ["MySQL-python"],
    "quantum_api_packages" => ["openstack-quantum"],
    "quantum_common_packages" => [
      "python-quantumclient",
      "openstack-quantum",
      "bridge-utils"
    ],
    "quantum_dhcp_packages" => ["openstack-quantum"],
    "quantum-dhcp-agent" => "quantum-dhcp-agent",
    "quantum_l3_packages" => ["openstack-quantum"],
    "quantum-l3-agent" => "quantum-l3-agent",
    "quantum_metadata_packages" => ["openstack-quantum"],
    "quantum-metadata-agent" => "quantum-metadata-agent",
    "quantum_api_service" => "quantum-server",
    "package_overrides" => "",
    "quantum_ovs_packages" => [
      'openstack-quantum-openvswitch'
    ],
    "quantum_ovs_service_name" => "quantum-openvswitch-agent",
    "quantum_openvswitch_service_name" => "openvswitch",
    "rpcdaemon" => "rpcdaemon"
  }
  default["quantum"]["ssl"]["dir"] = "/etc/pki/tls"
  default["quantum"]["ovs_use_veth"] = "True"

when "ubuntu"

  # Array of all the provider based networks to create
  default["quantum"]["ovs"]["provider_networks"] = [
    {
      "label" => "ph-eth1",
      "bridge" => "br-eth1",
      "vlans" => "1:1000"
    }
  ]

  default["nova-network"]["platform"] = {                                                   # node_attribute
    "nova_network_packages" => ["iptables", "nova-network"],
    "nova_network_service" => "nova-network",
    "nova_network_procmatch" => procmatch_base + 'nova-network\b',
    "common_packages" => ["nova-common", "python-nova", "python-novaclient"],
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }

  default["quantum"]["platform"] = {
    "mysql_python_packages" => ["python-mysqldb"],
    "quantum_common_packages" => ["python-quantumclient",
      "quantum-common", "python-quantum"],

    "quantum_api_packages" => ["quantum-server"],
    "quantum_api_service" => "quantum-server",

    "quantum_dhcp_packages" => ["dnsmasq-base", "dnsmasq-utils",
      "libnetfilter-conntrack3", "quantum-dhcp-agent" ],
    "quantum-dhcp-agent" => "quantum-dhcp-agent",

    "quantum_l3_packages" => ["quantum-l3-agent"],
    "quantum-l3-agent" => "quantum-l3-agent",

    "quantum_metadata_packages" => ["quantum-metadata-agent"],
    "quantum-metadata-agent" => "quantum-metadata-agent",

    "package_overrides" => "-o Dpkg::Options::='--force-confold' "\
      "-o Dpkg::Options::='--force-confdef'",

    "quantum_ovs_packages" => [
      "linux-headers-#{kernel['release']}",
      "openvswitch-datapath-lts-raring-dkms",
      "quantum-plugin-openvswitch",
      "quantum-plugin-openvswitch-agent"
    ],
    "quantum_ovs_service_name" => "quantum-plugin-openvswitch-agent",
    "quantum_openvswitch_service_name" => "openvswitch-switch",
    "rpcdaemon" => "rpcdaemon"
  }
  default["quantum"]["ssl"]["dir"] = "/etc/ssl"
  default["quantum"]["ovs_use_veth"] = "False"
end
