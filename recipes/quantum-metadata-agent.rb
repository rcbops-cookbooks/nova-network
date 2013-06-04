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
  action :nothing
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
nova_endpoint =
  get_access_endpoint("nova-api-os-compute", "nova", "api")
quantum_info =
  get_settings_by_recipe("nova-network\\:\\:nova-controller", "quantum")

template "/etc/quantum/metadata_agent.ini" do
  source "metadata_agent.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "service_pass" => quantum_info["service_pass"],
    "service_user" => quantum_info["service_user"],
    "service_tenant_name" => quantum_info["service_tenant_name"],
    "keystone_protocol" => ks_admin_endpoint["scheme"],
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_path" => ks_admin_endpoint["path"],
    "nova_metadata_ip" => nova_endpoint["host"],
    "quantum_debug" => node["quantum"]["debug"],
    "quantum_metadata_proxy_shared_secret" =>
      quantum_info["quantum_metadata_proxy_shared_secret"]
  )
  notifies :restart, "service[quantum-metadata-agent]", :immediately
  notifies :enable, "service[quantum-metadata-agent]", :immediately
end
