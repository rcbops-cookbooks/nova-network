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
default["nova"]["networks"]["public"] = {
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

default["nova"]["network"]["public_interface"] = "eth0"
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"
default["nova"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"
default["nova"]["network"]["dhcp_domain"] = "novalocal"
default["nova"]["network"]["force_dhcp_release"] = true
default["nova"]["network"]["send_arp_for_ha"] = true
default["nova"]["network"]["auto_assign_floating_ip"] = false
default["nova"]["network"]["floating_pool_name"] = "nova"
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
# Neutron Configuration Attributes
# ######################################################################### #
# nova.conf options for neutron
default["neutron"]["network_api_class"] = "nova.network.neutronv2.api.API"
default["neutron"]["auth_strategy"] = "keystone"
default["neutron"]["libvirt_vif_type"] = "ethernet"
default["neutron"]["libvirt_vif_driver"] =
  "nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver"
default["neutron"]["linuxnet_interface_driver"] =
  "nova.network.linux_net.LinuxOVSInterfaceDriver"
default["neutron"]["firewall_driver"] =
  "nova.virt.firewall.NoopFirewallDriver"

# Set the notification Driver
# Options are no_op, rpc, log, rabbit
default["neutron"]["notification"]["driver"] = "no_op"
default["neutron"]["notification"]["topics"] = "notifications"

default["neutron"]["database"]["sqlalchemy_pool_size"] = 10
default["neutron"]["database"]["max_overflow"] = 20
default["neutron"]["database"]["pool_timeout"] = 10

default["neutron"]["security_group_api"] = "neutron"
default["neutron"]["isolated_metadata"] = "True"
default["neutron"]["metadata_network"] = "False"
default["neutron"]["dnsmasq_lease_max"] = 16777216
default["neutron"]["service_neutron_metadata_proxy"] = "True"
default["neutron"]["agent_down_time"] = 30

default["neutron"]["services"]["api"]["scheme"] = "http"
default["neutron"]["services"]["api"]["network"] = "public"
default["neutron"]["services"]["api"]["port"] = 9696
default["neutron"]["services"]["api"]["path"] = ""
default["neutron"]["services"]["api"]["cert_file"] = "neutron.pem"
default["neutron"]["services"]["api"]["key_file"] = "neutron.key"
default["neutron"]["services"]["api"]["wsgi_file"] = "neutron-server"

default["neutron"]["db"]["name"] = "neutron"
default["neutron"]["db"]["username"] = "neutron"

default["neutron"]["service_tenant_name"] = "service"
default["neutron"]["service_user"] = "neutron"
default["neutron"]["service_role"] = "admin"
default["neutron"]["debug"] = "False"
default["neutron"]["verbose"] = "False"

default["neutron"]["overlap_ips"] = "True"
default["neutron"]["use_namespaces"] = "True" # should correspond to overlap_ips used for dhcp agent and l3 agent.

# Manage plugins here, currently only supports openvswitch (ovs)
default["neutron"]["plugin"] = "ovs"

# dhcp agent options
default["neutron"]["dhcp_lease_time"] = "1440"
default["neutron"]["dhcp_domain"] = "openstacklocal"

# neutron.conf options
default["neutron"]["quota_items"] = "network,subnet,port"
default["neutron"]["default_quota"] = "-1"
default["neutron"]["quota_network"] = "10"
default["neutron"]["quota_subnet"] = "10"
default["neutron"]["quota_port"] = "50"
default["neutron"]["quota_driver"] = "neutron.db.quota_db.DbQuotaDriver"

# Plugin defaults
# OVS
default["neutron"]["ovs"]["network_type"] = "vlan"
default["neutron"]["ovs"]["tunnel_ranges"] = "1:1000"           # Enumerating ranges of GRE tunnel IDs that are available for tenant network allocation (if GRE)
default["neutron"]["ovs"]["integration_bridge"] = "br-int"      # Don't change without a good reason..
default["neutron"]["ovs"]["tunnel_bridge"] = "br-tun"           # only used if tunnel_ranges is set
default["neutron"]["ovs"]["external_bridge"] = ""
default["neutron"]["ovs"]["external_interface"] = "eth1"
default["neutron"]["ovs"]["network"]="nova"
default["neutron"]["ovs"]["firewall_driver"] =
  "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"

# LBaaS defaults
default["neutron"]["lbaas"]["enabled"] = false
default["neutron"]["lbaas"]["device_driver"] =
  "neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver"

# FWaaS defaults
default["neutron"]["fwaas"]["enabled"] = false
default["neutron"]["fwaas"]["device_driver"] =
  "neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver"

# VPNaaS defaults
default["neutron"]["vpnaas"]["enabled"] = false
default["neutron"]["vpnaas"]["device_driver"] =
  "neutron.services.vpn.device_drivers.ipsec.OpenSwanDriver"
default["neutron"]["vpnaas"]["ipsec_status_check_interval"] = 60

# Generic regex for process pattern matching (to be used as a base pattern).
# Works for both Grizzly and Havana packages on Ubuntu and CentOS.
procmatch_base = '^((/usr/bin/)?python\d? )?(/usr/bin/)?'

case platform
when "fedora", "redhat", "centos"

  # Array of all the provider based networks to create
  default["neutron"]["ovs"]["provider_networks"] = [
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
    "common_packages" => ["openstack-nova-common", "python-cinderclient"]
  }

  default["neutron"]["platform"] = {
    "epel_openstack_packages" => ["kernel", "iproute"],
    "mysql_python_packages" => ["MySQL-python"],
    "neutron_api_packages" => ["openstack-neutron"],
    "neutron_common_packages" => [
      "python-neutronclient",
      "openstack-neutron",
      "bridge-utils"
    ],
    "neutron_dhcp_packages" => ["openstack-neutron"],
    "neutron-dhcp-agent" => "neutron-dhcp-agent",
    "neutron_lbaas_packages" => [],
    "neutron-lbaas-agent" => "neutron-lbaas-agent",
    "neutron_vpnaas_packages" => ["openswan", "openstack-neutron-vpn-agent"],
    "neutron-vpnaas-agent" => "neutron-vpn-agent",
    "neutron_l3_packages" => ["openstack-neutron"],
    "neutron-l3-agent" => "neutron-l3-agent",
    "neutron_metadata_packages" => ["openstack-neutron"],
    "neutron-metadata-agent" => "neutron-metadata-agent",
    "neutron_api_service" => "neutron-server",
    "package_options" => "",
    "neutron_ovs_packages" => [
      'openstack-neutron-openvswitch'
    ],
    "neutron_ovs_service_name" => "neutron-openvswitch-agent",
    "neutron_openvswitch_service_name" => "openvswitch",
    "rpcdaemon" => "rpcdaemon"
  }
  default["neutron"]["ssl"]["dir"] = "/etc/pki/tls"
  default["neutron"]["ovs_use_veth"] = "True"

when "ubuntu"

  # Array of all the provider based networks to create
  default["neutron"]["ovs"]["provider_networks"] = [
    {
      "label" => "ph-eth1",
      "bridge" => "br-eth1",
      "vlans" => "1:1000"
    }
  ]

  default["nova-network"]["platform"] = {
    "nova_network_packages" => ["iptables", "nova-network"],
    "nova_network_service" => "nova-network",
    "nova_network_procmatch" => procmatch_base + 'nova-network\b',
    "common_packages" => ["nova-common", "python-nova", "python-novaclient"]
  }

  default["neutron"]["platform"] = {
    "mysql_python_packages" => ["python-mysqldb"],
    "neutron_common_packages" => ["python-neutronclient",
      "neutron-common", "python-neutron"],

    "neutron_api_packages" => ["neutron-server"],
    "neutron_api_service" => "neutron-server",

    "neutron_dhcp_packages" => ["dnsmasq-base", "dnsmasq-utils",
      "libnetfilter-conntrack3", "neutron-dhcp-agent" ],
    "neutron-dhcp-agent" => "neutron-dhcp-agent",

    "neutron_l3_packages" => ["neutron-l3-agent"],
    "neutron-l3-agent" => "neutron-l3-agent",

    "neutron_lbaas_packages" => ["neutron-lbaas-agent"],
    "neutron-lbaas-agent" => "neutron-lbaas-agent",

    "neutron_vpnaas_packages" => ["openswan", "neutron-plugin-vpn-agent"],
    "neutron-vpnaas-agent" => "neutron-plugin-vpn-agent",

    "neutron_metadata_packages" => ["neutron-metadata-agent"],
    "neutron-metadata-agent" => "neutron-metadata-agent",

    "package_options" => "-o Dpkg::Options::='--force-confold' "\
      "-o Dpkg::Options::='--force-confdef'",

    "neutron_ovs_packages" => [
      "linux-headers-#{kernel['release']}",
      "openvswitch-datapath-dkms",
      "openvswitch-switch",
      "openvswitch-common",
      "neutron-plugin-openvswitch",
      "neutron-plugin-openvswitch-agent"
    ],
    "neutron_ovs_service_name" => "neutron-plugin-openvswitch-agent",
    "neutron_openvswitch_service_name" => "openvswitch-switch",
    "rpcdaemon" => "rpcdaemon"
  }
  default["neutron"]["ssl"]["dir"] = "/etc/ssl"
  default["neutron"]["ovs_use_veth"] = "False"
end
