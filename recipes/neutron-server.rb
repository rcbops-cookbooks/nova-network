#
# Cookbook Name:: nova-network
# Recipe:: neutron-server (API service)
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
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"

platform_options = node["neutron"]["platform"]

# If we're HA
if get_role_count("nova-network-controller") > 1
  # Grab the first controller
  neutron = get_settings_by_role("ha-controller1", "neutron")
  node.set["neutron"]["db"]["password"] =
    neutron["db"]["password"]
  node.set["neutron"]["service_pass"] =
    neutron["service_pass"]
  node.set["neutron"]["neutron_metadata_proxy_shared_secret"] =
    neutron["neutron_metadata_proxy_shared_secret"]
else # Make some stuff up
  if node["developer_mode"] == true
    node.set_unless["neutron"]["db"]["password"] =
      "neutron"
  else
    node.set_unless["neutron"]["db"]["password"] =
      secure_password
  end

  node.set_unless['neutron']['service_pass'] =
    secure_password
  node.set_unless["neutron"]["neutron_metadata_proxy_shared_secret"] =
    secure_password
end

unless Chef::Config[:solo]
  node.save
end

# Only do this setup once the db/service pass has been set.
include_recipe "nova-network::neutron-common"

packages = platform_options["neutron_api_packages"]

platform_options["neutron_api_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

ks_admin_endpoint =
  get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint =
  get_access_endpoint("keystone-api", "keystone", "service-api")
keystone =
  get_settings_by_role("keystone-setup", "keystone")

# Create db and user
# return connection info
# defined in osops-utils/libraries
mysql_info = create_db_and_user(
  "mysql",
  node["neutron"]["db"]["name"],
  node["neutron"]["db"]["username"],
  node["neutron"]["db"]["password"]
)

api_endpoint = get_bind_endpoint("neutron", "api")
access_endpoint = get_access_endpoint("nova-network-controller", "neutron", "api")

service "neutron-server" do
  service_name platform_options["neutron_api_service"]
  supports :status => true, :restart => true
  unless api_endpoint["scheme"] == "https"
    action :enable
    subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
    subscribes :restart, "template[/etc/neutron/api-paste.ini]", :delayed
    subscribes :restart, "template[/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL
if api_endpoint["scheme"] == "https"
  include_recipe "nova-network::neutron-server-ssl"
else
  if node.recipe?"apache2"
    apache_site "openstack-neutron-server" do
      enable false
      notifies :restart, "service[apache2]", :immediately
    end
  end
end

# Adds db Indexing for the hosts as found in the agents table.
# Defined in osops-utils/libraries

add_index_stopgap("mysql",
                  node["neutron"]["db"]["name"],
                  node["neutron"]["db"]["username"],
                  node["neutron"]["db"]["password"],
                  "rax_ix_host_index",
                  "agents",
                  "host",
                  "service[neutron-server]",
                  :run)

keystone_tenant "Register Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["neutron"]["service_tenant_name"]
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
  tenant_name node["neutron"]["service_tenant_name"]
  user_name node["neutron"]["service_user"]
  user_pass node["neutron"]["service_pass"]
  user_enabled true
  action :create
end

keystone_role "Grant 'admin' role to service user for service tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["neutron"]["service_tenant_name"]
  user_name node["neutron"]["service_user"]
  role_name node["neutron"]["service_role"]
  action :grant
end

keystone_register "Reqister Neutron Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "neutron"
  service_type "network"
  service_description "Neutron Network Service"
  action :create_service
end

keystone_register "Register Neutron Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "network"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl access_endpoint["uri"]
  endpoint_internalurl access_endpoint["uri"]
  endpoint_publicurl access_endpoint["uri"]
  action :create_endpoint
end
