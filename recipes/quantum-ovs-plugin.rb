# Cookbook Name:: nova-network
# Recipe:: quantum-ovs-plugin
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

node["quantum"][plugin]["packages"].each do |pkg|
    package pkg do
        action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
        options platform_options["package_overrides"]
    end
end

service "quantum-plugin-openvswitch-agent" do
    service_name node["quantum"]["ovs"]["service_name"]
    supports :status => true, :restart => true
    action :nothing
end

service "openvswitch-switch" do
    service_name "openvswitch-switch"
    supports :status => true, :restart => true
    action :nothing
end

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
api_endpoint = get_access_endpoint("nova-network-controller", "quantum", "api")
local_ip = get_ip_for_net('nova', node)		### FIXME
quantum_info = get_settings_by_recipe("nova-network\\:\\:nova-controller", "quantum")

template "/etc/quantum/api-paste.ini" do
    source "api-paste.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "keystone_api_ipaddress" => ks_admin_endpoint["host"],
        "keystone_admin_port" => ks_admin_endpoint["port"],
        "keystone_protocol" => ks_admin_endpoint["scheme"],
        "service_tenant_name" => quantum_info["service_tenant_name"],
        "service_user" => quantum_info["service_user"],
        "service_pass" => quantum_info["service_pass"]
    )
end

template "/etc/quantum/quantum.conf" do
    source "quantum.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "quantum_debug" => node["quantum"]["debug"],
        "quantum_verbose" => node["quantum"]["verbose"],
        "quantum_ipaddress" => api_endpoint["host"],
        "quantum_port" => api_endpoint["port"],
        "rabbit_ipaddress" => rabbit_info["host"],
        "rabbit_port" => rabbit_info["port"],
        "overlapping_ips" => node["quantum"]["overlap_ips"],
        "quantum_plugin" => node["quantum"]["plugin"]
    )
end

template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
    source "ovs_quantum_plugin.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "db_ip_address" => mysql_info["host"],
        "db_user" => quantum_info["db"]["username"],
        "db_password" => quantum_info["db"]["password"],
        "db_name" => quantum_info["db"]["name"],
        "ovs_network_type" => node["quantum"]["ovs"]["network_type"],
        "ovs_enable_tunneling" => node["quantum"]["ovs"]["tunneling"],
        "ovs_tunnel_ranges" => node["quantum"]["ovs"]["tunnel_ranges"],
        "ovs_integration_bridge" => node["quantum"]["ovs"]["integration_bridge"],
        "ovs_tunnel_bridge" => node["quantum"]["ovs"]["tunnel_bridge"],
        "ovs_debug" => node["quantum"]["debug"],
        "ovs_verbose" => node["quantum"]["verbose"],
        "ovs_local_ip" => local_ip
    )
    # notifies :restart, resources(:service => "quantum-server"), :immediately
    notifies :restart, resources(:service => "quantum-plugin-openvswitch-agent"), :immediately
    notifies :enable, resources(:service => "quantum-plugin-openvswitch-agent"), :immediately
    notifies :restart, resources(:service => "openvswitch-switch"), :immediately
end

execute "create integration bridge" do
    command "ovs-vsctl add-br #{node["quantum"]["ovs"]["integration_bridge"]}"
    action :run
    not_if "ovs-vsctl show | grep 'Bridge br-int'" ## FIXME
end
