# Cookbook Name:: nova-network
# Recipe:: quantum-l3-agent
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

if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
end

if not node["package_component"].nil?
    release = node["package_component"]
else
    release = "folsom"
end

platform_options = node["quantum"]["platform"][release]
plugin = node["quantum"]["plugin"]

platform_options["quantum_l3_packages"].each do |pkg|
    package pkg do
        action :upgrade
        options platform_options["package_overrides"]
    end
end

service "quantum-l3-agent" do
    service_name platform_options["quantum_l3_agent"]
    supports :status => true, :restart => true
    action :nothing
end

ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
metadata_ip = get_ip_for_net("nova", search(:node, "recipes:nova\\:\\:api-metadata AND chef_environment:#{node.chef_environment}"))

template "/etc/quantum/l3_agent.ini" do
    source "#{release}/l3_agent.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "quantum_external_bridge" => node["quantum"][plugin]["external_bridge"],
        "nova_metadata_ip" => metadata_ip,
        "service_pass" => node["quantum"]["service_pass"],
        "service_user" => node["quantum"]["service_user"],
        "service_tenant_name" => node["quantum"]["service_tenant_name"],
        "keystone_protocol" => ks_admin_endpoint["scheme"],
        "keystone_api_ipaddress" => ks_admin_endpoint["host"],
        "keystone_admin_port" => ks_admin_endpoint["port"],
        "keystone_path" => ks_admin_endpoint["path"],
        "quantum_debug" => node["quantum"]["debug"],
        "quantum_verbose" => node["quantum"]["verbose"],
        "quantum_namespace" => node["quantum"]["use_namespaces"],
        "quantum_plugin" => node["quantum"]["plugin"]
    )
    notifies :restart, resources(:service => "quantum-l3-agent"), :immediately
    notifies :enable, resources(:service => "quantum-l3-agent"), :immediately
end
