#
# Cookbook Name:: nova-network
# Recipe:: quantum-server (API service)
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
#
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "osops-utils"

platform_options = node["quantum"]["platform"]

quantum = get_settings_by_role("quantum-setup", "quantum")

# Only do this setup once the db/service pass has been set.
include_recipe "nova-network::quantum-common"

packages = platform_options["quantum_api_packages"]

platform_options["quantum_api_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

# Get the keystone endpoints
ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint =
  get_access_endpoint("keystone-api", "keystone", "service-api")
keystone =
  get_settings_by_role("keystone-setup", "keystone")

# Get the api endpoints
api_endpoint = get_bind_endpoint("quantum", "api")
access_endpoint = get_access_endpoint("nova-network-controller", "quantum", "api")

# Setup and configure the service
service "quantum-server" do
  service_name platform_options["quantum_api_service"]
  supports :status => true, :restart => true
  unless api_endpoint["scheme"] == "https"
    action :enable
    subscribes :restart, "template[/etc/quantum/quantum.conf]", :delayed
    subscribes :restart, "template[/etc/quantum/api-paste.ini]", :delayed
    subscribes :restart, "template[/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL if required
if api_endpoint["scheme"] == "https"
  include_recipe "nova-network::quantum-server-ssl"
else
  if node.recipe?"apache2"
    apache_site "openstack-quantum-server" do
      enable false
      notifies :run, "execute[restore-selinux-context]", :immediately
      notifies :restart, "service[apache2]", :immediately
    end
  end
end

keystone_tenant "Register Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["quantum"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled true
  action :create
end

keystone_user "Register Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["quantum"]["service_tenant_name"]
  user_name node["quantum"]["service_user"]
  user_pass node["quantum"]["service_pass"]
  user_enabled true
  action :create
end

keystone_role "Grant 'admin' role to service user for service tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["quantum"]["service_tenant_name"]
  user_name node["quantum"]["service_user"]
  role_name node["quantum"]["service_role"]
  action :grant
end

keystone_register "Reqister Quantum Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "quantum"
  service_type "network"
  service_description "Quantum Network Service"
  action :create_service
end

keystone_register "Register Quantum Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "network"
  endpoint_region "RegionOne"
  endpoint_adminurl access_endpoint["uri"]
  endpoint_internalurl access_endpoint["uri"]
  endpoint_publicurl access_endpoint["uri"]
  action :create_endpoint
end
