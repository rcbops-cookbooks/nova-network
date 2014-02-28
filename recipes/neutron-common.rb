#
# Cookbook Name:: nova-network
# Recipe:: neutron-server (API service)
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

platform_options = node["neutron"]["platform"]

packages = platform_options["neutron_common_packages"] +
  platform_options["mysql_python_packages"]

packages.each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

#Kill quantum-ns-metadata-proxy proccess per GH 761
execute "kill quantum metadata-proxy proccess" do
  command "pkill -9 -f quantum-ns-metadata-proxy"
  returns [1,0]
  action :run
  only_if { node["osops"]["do_package_upgrades"] }
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint =
  get_access_endpoint("keystone-api", "keystone", "service-api")
keystone =
  get_settings_by_role("keystone-setup", "keystone")
rabbit_info =
  get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
rabbit_settings =
  get_settings_by_role("rabbitmq-server", "rabbitmq")
api_endpoint =
  get_bind_endpoint("neutron", "api")
mysql_info = get_mysql_endpoint
neutron_info = get_settings_by_role("nova-network-controller", "neutron")
local_ip = get_ip_for_net(node["neutron"]["ovs"]["network"], node)

# A comma-separated list of provider network vlan ranges
# => "ph-eth1:1:1000,ph-eth0:1001:1024"
vlan_ranges = node["neutron"]["ovs"]["provider_networks"].map do |network|
  if network.has_key?('vlans') and not network['vlans'].empty?
    network['vlans'].split(',').each do |vlan_range|
      vlan_range.prepend("#{network['label']}:")
    end
  else
    network['label']
  end
end.join(',')

# A comma-separated list of provider network to bridge mappings
# => "ph-eth1:br-eth1,ph-eth0:br-eth0"
bridge_mappings = node["neutron"]["ovs"]["provider_networks"].map do |network|
  "#{network['label']}:#{network['bridge']}"
end.join(',')

# Make sure our permissions are not too, well, permissive
directory "/etc/neutron/" do
  action :create
  owner "root"
  group "neutron"
  mode "750"
end

# *-controller role by itself won't install the OVS plugin, despite
# neutron-server requiring the plugin's config file, so... make go
directory "/etc/neutron/plugins/openvswitch" do
  action :create
  owner "root"
  group "neutron"
  mode "750"
  recursive true
end

notification_provider = node["neutron"]["notification"]["driver"]
case notification_provider
when "no_op"
  notification_driver = "neutron.openstack.common.notifier.no_op_notifier"
when "rpc"
  notification_driver = "neutron.openstack.common.notifier.rpc_notifier"
when "log"
  notification_driver = "neutron.openstack.common.notifier.log_notifier"
else
  notification_driver = nil
  msg = "#{notification_provider}, is not currently supported by these cookbooks."
  Chef::Application.fatal! msg
end

# Use service_plugins array to pass all service plugins to the conf at once
service_plugins = []
if node["neutron"]["lbaas"]["enabled"]
  #Add Load balancer to service_plugins array
  service_plugins << "neutron.services.loadbalancer.plugin.LoadBalancerPlugin"
  lbaas_provider = "LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default"
else
  lbaas_provider = false
end

if node["neutron"]["fwaas"]["enabled"]
  # Add Firewall to service_plugins array
  service_plugins << "neutron.services.firewall.fwaas_plugin.FirewallPlugin"
  fwaas_provider = "FIREWALL:Iptables:neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver:default"
  include_recipe "nova-network::neutron-fwaas"
else
  fwaas_provider = false
end

if node["neutron"]["vpnaas"]["enabled"]
  # Add Firewall to service_plugins array
  service_plugins << "neutron.services.vpn.plugin.VPNDriverPlugin"
  vpnaas_provider = "VPN:Vpn:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default"
  include_recipe "nova-network::neutron-vpnaas"
else
  vpnaas_provider = false
end

cookbook_file "/etc/neutron/policy.json" do
  source "policy.json"
  mode 0644
  owner "root"
  group "neutron"
end

template "/etc/neutron/neutron.conf" do
  source "neutron.conf.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "neutron_debug" => node["neutron"]["debug"],
    "neutron_verbose" => node["neutron"]["verbose"],
    "neutron_ipaddress" => api_endpoint["host"],
    "neutron_port" => api_endpoint["port"],
    "neutron_namespace" => node["neutron"]["use_namespaces"],
    "neutron_ovs_use_veth" => node["neutron"]["ovs_use_veth"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_ha_queues" => rabbit_settings["cluster"],
    "rabbit_port" => rabbit_info["port"],
    "overlapping_ips" => node["neutron"]["overlap_ips"],
    "neutron_plugin" => node["neutron"]["plugin"],
    "quota_items" => node["neutron"]["quota_items"],
    "default_quota" => node["neutron"]["default_quota"],
    "quota_network" => node["neutron"]["quota_network"],
    "quota_subnet" => node["neutron"]["quota_subnet"],
    "quota_port" => node["neutron"]["quota_port"],
    "quota_driver" => node["neutron"]["quota_driver"],
    "service_pass" => neutron_info["service_pass"],
    "service_user" => neutron_info["service_user"],
    "service_tenant_name" => neutron_info["service_tenant_name"],
    "auth_region" => node["osops"]["region"],
    "keystone_protocol" => ks_admin_endpoint["scheme"],
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "dhcp_lease_time" => node["neutron"]["dhcp_lease_time"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_path" => ks_admin_endpoint["path"],
    "agent_down_time" => node["neutron"]["agent_down_time"],
    "notification_driver" => notification_driver,
    "notification_topics" => node["neutron"]["notification"]["topics"],
    "lbaas_provider" => lbaas_provider,
    "fwaas_provider" => fwaas_provider,
    "vpnaas_provider" => vpnaas_provider,
    "service_plugins" => service_plugins,
    "sql_max_pool_size" => node["neutron"]["database"]["sqlalchemy_pool_size"],
    "sql_max_overflow" => node["neutron"]["database"]["max_overflow"],
    "sql_pool_timeout" => node["neutron"]["database"]["pool_timeout"]
  )
end

template "/etc/neutron/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_protocol" => ks_admin_endpoint["scheme"],
    "service_tenant_name" => neutron_info["service_tenant_name"],
    "service_user" => neutron_info["service_user"],
    "service_pass" => neutron_info["service_pass"]
  )
end

template "/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini" do
  source "ovs_neutron_plugin.ini.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "db_ip_address" => mysql_info["host"],
    "db_user" => neutron_info["db"]["username"],
    "db_password" => neutron_info["db"]["password"],
    "db_name" => neutron_info["db"]["name"],
    "ovs_firewall_driver" => node["neutron"]["ovs"]["firewall_driver"],
    "ovs_network_type" => node["neutron"]["ovs"]["network_type"],
    "ovs_tunnel_ranges" => node["neutron"]["ovs"]["tunnel_ranges"],
    "ovs_integration_bridge" => node["neutron"]["ovs"]["integration_bridge"],
    "ovs_tunnel_bridge" => node["neutron"]["ovs"]["tunnel_bridge"],
    "sqlalchemy_pool_size" => node["neutron"]["database"]["sqlalchemy_pool_size"],
    "ovs_vlan_range" => vlan_ranges,
    "ovs_bridge_mapping" => bridge_mappings,
    "ovs_debug" => node["neutron"]["debug"],
    "ovs_verbose" => node["neutron"]["verbose"],
    "ovs_local_ip" => local_ip
  )
end

case node['platform']
  when 'redhat', 'centos'
    link "/etc/neutron/plugin.ini" do
      to "/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini"
    end

  # RHEL YOUR DOING IT WRONG!
  cookbook_file "/usr/share/neutron/neutron-dist.conf" do
    source "neutron-dist.conf"
    mode 0644
    owner "root"
    group "neutron"
  end
end
