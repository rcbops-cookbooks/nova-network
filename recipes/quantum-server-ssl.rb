#
# Cookbook Name:: nova-network
# Recipe:: quantum-server-ssl
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
#

include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"
include_recipe "osops-utils::ssl_packages"

# Remove monit conf file if it exists
if node.attribute?"monit"
  if node["monit"].attribute?"conf.d_dir"
    file "#{node['monit']['conf.d_dir']}/nova-network.conf" do
      action :delete
      notifies :reload, "service[monit]", :immediately
    end
  end
end

# setup cert files
case node["platform"]
when "ubuntu", "debian"
  grp = "ssl-cert"
else
  grp = "root"
end

cookbook_file "#{node["quantum"]["ssl"]["dir"]}/certs/#{node["quantum"]["services"]["api"]["cert_file"]}" do
  source "quantum.pem"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "#{node["quantum"]["ssl"]["dir"]}/private/#{node["quantum"]["services"]["api"]["key_file"]}" do
  source "quantum.key"
  mode 0644
  owner "root"
  group grp
end

# setup wsgi file

directory "#{node["apache"]["dir"]}/wsgi" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["quantum"]["services"]["api"]["wsgi_file"]}" do
  source "quantum_modwsgi.py"
  mode 0644
  owner "root"
  group "root"
end

api_bind = get_bind_endpoint("quantum", "api")

unless node["quantum"]["services"]["api"].attribute?"cert_override"
  cert_location = "#{node["quantum"]["ssl"]["dir"]}/certs/#{node["quantum"]["services"]["api"]["cert_file"]}"
else
  cert_location = node["quantum"]["services"]["api"]["cert_override"]
end

unless node["quantum"]["services"]["api"].attribute?"key_override"
  key_location = "#{node["quantum"]["ssl"]["dir"]}/private/#{node["quantum"]["services"]["api"]["key_file"]}"
else
  key_location = node["quantum"]["services"]["api"]["key_override"]
end

template value_for_platform(
  ["ubuntu", "debian", "fedora"] => {
    "default" => "#{node["apache"]["dir"]}/sites-available/openstack-quantum-server"
  },
  "fedora" => {
    "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-quantum-server"
  },
  ["redhat", "centos"] => {
    "default" => "#{node["apache"]["dir"]}/conf.d/openstack-quantum-server"
  },
  "default" => {
    "default" => "#{node["apache"]["dir"]}/openstack-quantum-server"
  }
) do
  source "modwsgi_vhost.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :listen_ip => api_bind["host"],
    :service_port => api_bind["port"],
    :cert_file => cert_location,
    :key_file => key_location,
    :wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["quantum"]["services"]["api"]["wsgi_file"]}",
    :proc_group => "quantum-server",
    :log_file => "/var/log/quantum/quantum-server.log"
  )
  notifies :reload, "service[apache2]", :delayed
end

apache_site "openstack-quantum-server" do
  enable true
  notifies :restart, "service[apache2]", :immediately
end
