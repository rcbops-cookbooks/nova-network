#
# Cookbook Name:: nova-network
# Recipe:: quantum-metadata-agent
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

platform_options["quantum_metadata_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

service "quantum-metadata-agent" do
  service_name platform_options["quantum_metadata_agent"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "template[/etc/quantum/quantum.conf]", :delayed
  subscribes :restart, "template[/etc/quantum/metadata_agent.ini]", :delayed
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
nova_endpoint =
  get_access_endpoint("nova-api-os-compute", "nova", "api")
quantum_info = get_settings_by_role("nova-network-controller", "quantum")

# install a crontab to run the quantum-netns-cleanup script every night
# at 00:00
cron "quantum-netns-cleanup" do
  minute "00"
  hour "00"
  command "/usr/bin/quantum-netns-cleanup"
end

template "/etc/quantum/metadata_agent.ini" do
  source "metadata_agent.ini.erb"
  owner "root"
  group "quantum"
  mode "0640"
  variables(
    "nova_metadata_ip" => nova_endpoint["host"],
    "quantum_metadata_proxy_shared_secret" =>
      quantum_info["quantum_metadata_proxy_shared_secret"]
  )
end
