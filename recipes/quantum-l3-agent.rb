# Cookbook Name:: nova-network
# Recipe:: quantum-l3-agent
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

include_recipe "osops-utils"
include_recipe "sysctl::default"
include_recipe "nova-network::quantum-common"

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
end

sysctl 'net.ipv4.ip_forward' do
  value '1'
end


platform_options = node["quantum"]["platform"]
plugin = node["quantum"]["plugin"]

platform_options["quantum_l3_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

service "quantum-l3-agent" do
  service_name platform_options["quantum_l3_agent"]
  supports :status => true, :restart => true
  action :nothing
  subscribes :restart, "template[/etc/quantum/quantum.conf]", :delayed
  subscribes :restart, "template[/etc/l3-agent.ini]", :delayed
end

execute "create external bridge" do
  command "ovs-vsctl add-br #{node["quantum"]["ovs"]["external_bridge"]}"
  action :run
  not_if "ovs-vsctl show | grep \"Bridge #{node["quantum"]["ovs"]["external_bridge"]}\""
end

if node['quantum']['ovs'].has_key?('external_interface') and not node['quantum']['ovs']['external_interface'].empty?
  Chef::Log.info("External interface set to #{node['quantum']['ovs']['external_interface']}.")
  if node['network']['interfaces'].has_key?(node['quantum']['ovs']['external_interface'])
    execute "add external interface to external bridge" do
      command "ovs-vsctl add-port #{node['quantum']['ovs']['external_bridge']} #{node['quantum']['ovs']['external_interface']}"
      action :run
      not_if "ovs-vsctl iface-to-br #{node['quantum']['ovs']['external_interface']}"
    end
  else
    Chef::Log.warn("Interface #{node['quantum']['ovs']['external_interface']} does not exist!")
  end
else
  Chef::Log.warn("No external interface is set.")
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
quantum_info =
  get_settings_by_recipe("nova-network\\:\\:nova-controller", "quantum")
nova_info =
  get_access_endpoint("nova-api-os-compute", "nova", "api")
metadata_ip =
  nova_info["host"]

template "/etc/quantum/l3_agent.ini" do
  source "l3_agent.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "quantum_external_bridge" => node["quantum"][plugin]["external_bridge"],
    "nova_metadata_ip" => metadata_ip,
    "quantum_plugin" => node["quantum"]["plugin"],
    "l3_router_id" => node["quantum"]["l3"]["router_id"],
    "l3_gateway_net_id" => node["quantum"]["l3"]["gateway_external_net_id"]
  )
  notifies :restart, "service[quantum-l3-agent]", :delayed
  notifies :enable, "service[quantum-l3-agent]", :delayed
end
