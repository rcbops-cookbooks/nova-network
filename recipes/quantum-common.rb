#
# Cookbook Name:: nova-network
# Recipe:: quantum-server (API service)
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

platform_options = node["quantum"]["platform"]

packages = platform_options["quantum_common_packages"] +
  platform_options["mysql_python_packages"]

packages.each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint =
  get_access_endpoint("keystone-api", "keystone", "service-api")
keystone =
  get_settings_by_role("keystone-setup", "keystone")
rabbit_info =
  get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
api_endpoint =
  get_access_endpoint("nova-network-controller", "quantum", "api")
mysql_info =
  get_access_endpoint("mysql-master", "mysql", "db")
quantum_info = get_settings_by_role("nova-network-controller", "quantum")
local_ip = get_ip_for_net('nova', node)
vlan_ranges = node["quantum"]["ovs"]["provider_networks"].
  collect { |k,v| "#{k}:#{v['vlans']}"}.join(',')
bridge_mappings = node["quantum"]["ovs"]["provider_networks"].
  collect { |k,v| "#{k}:#{v['bridge']}"}.join(',')

template "/etc/quantum/quantum.conf" do
  source "quantum.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "quantum_debug" => node["quantum"]["debug"],
    "quantum_verbose" => node["quantum"]["verbose"],
    "quantum_ipaddress" => api_endpoint["host"],
    "quantum_port" => api_endpoint["port"],
    "quantum_namespace" => node["quantum"]["use_namespaces"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "overlapping_ips" => node["quantum"]["overlap_ips"],
    "quantum_plugin" => node["quantum"]["plugin"],
    "quota_items" => node["quantum"]["quota_items"],
    "default_quota" => node["quantum"]["default_quota"],
    "quota_network" => node["quantum"]["quota_network"],
    "quota_subnet" => node["quantum"]["quota_subnet"],
    "quota_port" => node["quantum"]["quota_port"],
    "quota_driver" => node["quantum"]["quota_driver"],
    "service_pass" => quantum_info["service_pass"],
    "service_user" => quantum_info["service_user"],
    "service_tenant_name" => quantum_info["service_tenant_name"],
    "keystone_protocol" => ks_admin_endpoint["scheme"],
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "dhcp_lease_time" => node["quantum"]["dhcp_lease_time"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_path" => ks_admin_endpoint["path"]
  )
end

template "/etc/quantum/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_protocol" => ks_admin_endpoint["scheme"],
    "service_tenant_name" => quantum_info["service_tenant_name"],
    "service_user" => quantum_info["service_user"],
    "service_pass" => quantum_info["service_pass"]
  )
end

template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
  source "ovs_quantum_plugin.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "db_ip_address" => mysql_info["host"],
    "db_user" => quantum_info["db"]["username"],
    "db_password" => quantum_info["db"]["password"],
    "db_name" => quantum_info["db"]["name"],
    "ovs_firewall_driver" => node["quantum"]["ovs"]["firewall_driver"],
    "ovs_network_type" => node["quantum"]["ovs"]["network_type"],
    "ovs_tunnel_ranges" => node["quantum"]["ovs"]["tunnel_ranges"],
    "ovs_integration_bridge" => node["quantum"]["ovs"]["integration_bridge"],
    "ovs_tunnel_bridge" => node["quantum"]["ovs"]["tunnel_bridge"],
    "ovs_vlan_range" => vlan_ranges,
    "ovs_bridge_mapping" => bridge_mappings,
    "ovs_debug" => node["quantum"]["debug"],
    "ovs_verbose" => node["quantum"]["verbose"],
    "ovs_local_ip" => local_ip
  )
end
