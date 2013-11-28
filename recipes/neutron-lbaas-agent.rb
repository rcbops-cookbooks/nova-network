#
# Cookbook Name:: nova-network
# Recipe:: neutron-lbaas-agent
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
if node["neutron"]["lbaas"]["enabled"]
  platform_options["neutron_lbaas_packages"].each do |pkg|
    package pkg do
      action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
      options platform_options["package_options"]
    end
  end

  service "neutron-lbaas-agent" do
    service_name platform_options["neutron-lbaas-agent"]
    supports :status => true, :restart => true
    action :nothing
    subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
    subscribes :restart, "template[/etc/neutron/lbaas_agent.ini]", :delayed
  end

    template "/etc/neutron/lbaas_agent.ini" do
    source "lbaas_agent.ini.erb"
    owner "root"
    group "neutron"
    mode "0640"
    variables(
      "neutron_plugin" => node["neutron"]["plugin"],
      "device_driver" => node["neutron"]["lbaas"]["device_driver"])
  end
end
