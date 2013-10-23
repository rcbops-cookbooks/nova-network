#
# Cookbook Name:: nova-network
# Recipe:: neutron-metadata-agent
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

platform_options["neutron_metadata_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "neutron-metadata-agent" do
  service_name platform_options["neutron_metadata_agent"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/neutron/metadata_agent.ini]", :delayed
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
nova_endpoint =
  get_access_endpoint("nova-api-os-compute", "nova", "api")
neutron_info = get_settings_by_role("nova-network-controller", "neutron")

# install a crontab to run the neutron-netns-cleanup script every night
# at 00:00
cron "neutron-netns-cleanup" do
  minute "00"
  hour "00"
  command "/usr/bin/neutron-netns-cleanup"
end

template "/etc/neutron/metadata_agent.ini" do
  source "metadata_agent.ini.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "nova_metadata_ip" => nova_endpoint["host"],
    "neutron_metadata_proxy_shared_secret" =>
      neutron_info["neutron_metadata_proxy_shared_secret"]
  )
end
