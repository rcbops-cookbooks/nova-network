#
# Cookbook Name:: nova-network
# Recipe:: neutron-vpnaas
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

#Must set neutron lbaas enabled attr to true to install lbaas
platform_options["neutron_vpnaas_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "neutron-vpnaas-agent" do
  service_name platform_options["neutron-vpnaas-agent"]
  supports :status => true, :restart => true
  action :nothing
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/neutron/vpn_agent.ini]", :delayed
  subscribes :restart, "cookbook_file[/etc/neutron/rootwrap.d/vpnaas.filters]", :delayed
end

template "/etc/neutron/vpn_agent.ini" do
  source "vpn_agent.ini.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "neutron_plugin" => node["neutron"]["plugin"],
    "device_driver" => node["neutron"]["vpnaas"]["device_driver"],
    "ipsec_status_check_interval" => node["neutron"]["vpnaas"]["ipsec_status_check_interval"]
  )
end

# Create our root wrap directory
directory "/etc/neutron/rootwrap.d" do
  action :create
  owner "root"
  group "neutron"
  mode "755"
end

cookbook_file "/etc/neutron/rootwrap.d/vpnaas.filters" do
  source "vpnaas.filters"
  owner "root"
  group "neutron"
  mode "0640"
end
