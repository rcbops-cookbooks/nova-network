# Cookbook Name:: nova-network
# Recipe:: neutron-ovs-plugin
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


platform_options["neutron_#{plugin}_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "neutron-plugin-openvswitch-agent" do
  service_name platform_options["neutron_ovs_service_name"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini]", :delayed
end

service "openvswitch-switch" do
  service_name platform_options['neutron_openvswitch_service_name']
  supports :status => true, :restart => true
  action [:enable, :start]
end

execute "create integration bridge" do
  command "ovs-vsctl add-br #{node["neutron"]["ovs"]["integration_bridge"]}"
  action :run
  not_if "ovs-vsctl get bridge \"#{node["neutron"]["ovs"]["integration_bridge"]}\" name"
end

node["neutron"]["ovs"]["provider_networks"].each do |network|
  execute "create provider bridge #{network['bridge']}" do
    command "ovs-vsctl add-br #{network['bridge']}"
    action :run
    notifies :restart, "service[neutron-plugin-openvswitch-agent]", :delayed
    not_if "ovs-vsctl get bridge \"#{network['bridge']}\" name" ## FIXME
  end
end

case node['platform']
when 'redhat', 'centos'
  platform_options['epel_openstack_packages'].each do |pkg|
    package pkg do
      # Since these packages are already installed from [base] and we want
      # to replace them, we need action :upgrade to make chef install the
      # alternate versions.
      # XXX Assumes versions from [epel-openstack] > [base]
      action :upgrade

      # Force yum to search the epel-openstack repo.
      # FIXME(brett) Don't hardcode repo name (hardcoded in osops::packages).
      #   Maybe dynamically get name from `yum repolist'.
      options '--disablerepo="*" --enablerepo=epel-openstack'

      # To protect ourselves from future chef runs, don't always upgrade
      # packages when updates are available (maybe consider checking
      # 'do_package_upgrades' though?).  Unfortunately the release versioning
      # convention isn't consistent across packages in this repo, so we can't
      # simply grep 'openstack' or similar.
      not_if "rpm -q --qf '%{RELEASE}\\n' #{pkg} |grep -E '\\.el6(ost|\\.gre)\\.'"
    end
  end
end
