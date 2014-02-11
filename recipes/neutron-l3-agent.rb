# Cookbook Name:: nova-network
# Recipe:: neutron-l3-agent
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
include_recipe "nova-network::neutron-common"

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
end

sysctl 'net.ipv4.ip_forward' do
  value '1'
end


platform_options = node["neutron"]["platform"]
plugin = node["neutron"]["plugin"]

platform_options["neutron_l3_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "neutron-l3-agent" do
  service_name platform_options["neutron_l3_agent"]
  supports :status => true, :restart => true
  action :nothing
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/neutron/l3-agent.ini]", :delayed
end


execute "create external bridge" do
  command "ovs-vsctl add-br #{node["neutron"]["ovs"]["external_bridge"]}"
  action :run
  not_if "ovs-vsctl get bridge \"#{node["neutron"]["ovs"]["external_bridge"]}\" name"
  not_if { node["neutron"]["ovs"]["external_bridge"].nil? }
  not_if { node["neutron"]["ovs"]["external_bridge"].empty? }
end


nova_info =
  get_access_endpoint("nova-api-os-compute", "nova", "api")
metadata_ip =
  nova_info["host"]

template "/etc/neutron/l3_agent.ini" do
  source "l3_agent.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "neutron_external_bridge" => node["neutron"][plugin]["external_bridge"],
    "nova_metadata_ip" => metadata_ip,
    "neutron_plugin" => node["neutron"]["plugin"]
  )
  notifies :restart, "service[neutron-l3-agent]", :delayed
  notifies :enable, "service[neutron-l3-agent]", :delayed
end
