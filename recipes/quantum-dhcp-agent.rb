#
# Cookbook Name:: nova-network
# Recipe:: quantum-dhcp-agent
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

include_recipe "osops-utils"
include_recipe "nova-network::quantum-common"

platform_options = node["quantum"]["platform"]
plugin = node["quantum"]["plugin"]

platform_options["quantum_dhcp_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

service "quantum-dhcp-agent" do
  service_name platform_options["quantum_dhcp_agent"]
  supports :status => true, :restart => true
  action :nothing
  subscribes :restart, "template[/etc/quantum/quantum.conf]", :delayed
  subscribes :restart, "template[/etc/dhcp_agent.ini]", :delayed
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
quantum_info =
  get_settings_by_recipe("nova-network\\:\\:nova-controller", "quantum")

template "/etc/quantum/dhcp_agent.ini" do
  source "dhcp_agent.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "quantum_isolated" => node["quantum"]["isolated_metadata"],
    "quantum_plugin" => node["quantum"]["plugin"]
  )
end
