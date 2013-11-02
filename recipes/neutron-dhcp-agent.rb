#
# Cookbook Name:: nova-network
# Recipe:: neutron-dhcp-agent
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
include_recipe "nova-network::neutron-common"

platform_options = node["neutron"]["platform"]
plugin = node["neutron"]["plugin"]

platform_options["neutron_dhcp_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "neutron-dhcp-agent" do
  service_name platform_options["neutron_dhcp_agent"]
  supports :status => true, :restart => true
  action :nothing
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/dhcp_agent.ini]", :delayed
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
neutron_info =
  get_settings_by_recipe("nova-network\\:\\:nova-controller", "neutron")

template "/etc/neutron/dhcp_agent.ini" do
  source "dhcp_agent.ini.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "use_debug" => node["neutron"]["debug"],
    "dnsmasq_lease" => node["neutron"]["dnsmasq_lease_max"],
    "neutron_metadata_network" => node["neutron"]["metadata_network"],
    "neutron_isolated" => node["neutron"]["isolated_metadata"],
    "neutron_plugin" => node["neutron"]["plugin"],
    "neutron_dhcp_domain" => node["neutron"]["dhcp_domain"]
  )
end
