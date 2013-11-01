#
# Cookbook Name:: nova-network
# Recipe:: rpcdaemon
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

platform_options = node["neutron"]["platform"]

# Ensure package repository.  This should go elsewhere, but
# I'm not sure this is the right place for these packages.
case node["platform_family"]
when "rhel"
  include_recipe "yum::epel"

  yum_key "RPM-GPG-KEY-nova-extras" do
    url "http://download.opensuse.org/repositories/home:/rpedde:/openstack/CentOS_CentOS-6/repodata/repomd.xml.key"
    action :add
  end

  yum_repository "nova-extras" do
    repo_name "nova-extras"
    key "RPM-GPG-KEY-nova-extras"
    url "http://download.opensuse.org/repositories/home:/rpedde:/openstack/CentOS_CentOS-6/"
    type "rpm-md"
  end
when "debian"
  include_recipe "apt::default"

  apt_repository "nova-extras" do
    uri "http://download.opensuse.org/repositories/home:/rpedde:/openstack/xUbuntu_12.04"
    distribution "/"
    key "http://download.opensuse.org/repositories/home:/rpedde:/openstack/xUbuntu_12.04/Release.key"
  end
end


# install the rpc daemon package
package "rpcdaemon" do
  action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  options platform_options["package_options"]
end

rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

# drop the config file
template "/etc/rpcdaemon.conf" do
  source "rpcdaemon.conf.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "rabbit_ipaddress" => rabbit_info["host"]
  )
end

# TODO: Monitization.  Not Monetization.  Monitization.

# Ensure service is started and running.
service "rpcdaemon" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end
