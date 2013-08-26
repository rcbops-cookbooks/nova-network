# Cookbook Name:: nova-network
# Recipe:: quantum-ovs-plugin
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
include_recipe "nova-network::quantum-common"

platform_options = node["quantum"]["platform"]
plugin = node["quantum"]["plugin"]


platform_options["quantum_#{plugin}_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

service "quantum-plugin-openvswitch-agent" do
  service_name platform_options["quantum_ovs_service_name"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "template[/etc/quantum/quantum.conf]", :delayed
  subscribes :restart, "template[/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini]", :delayed
end

service "openvswitch-switch" do
  service_name platform_options['quantum_openvswitch_service_name']
  supports :status => true, :restart => true
  action [:enable, :start]
end

execute "create integration bridge" do
  command "ovs-vsctl add-br #{node["quantum"]["ovs"]["integration_bridge"]}"
  action :run
  not_if "ovs-vsctl list-br | grep #{node["quantum"]["ovs"]["integration_bridge"]}"
end

node["quantum"]["ovs"]["provider_networks"].each do |network|
  execute "create provider bridge #{network['bridge']}" do
    command "ovs-vsctl add-br #{network['bridge']}"
    action :run
    notifies :restart, "service[quantum-plugin-openvswitch-agent]", :delayed
    not_if "ovs-vsctl list-br | grep #{network['bridge']}" ## FIXME
  end
end

case node['platform']
when 'redhat', 'centos'
  platform_options['epel_openstack_packages'].each do |pkg|
    package pkg do
      # Since these packages are already installed from [base] and we want
      # to replace them, we need action :upgrade to make chef install the
      # alternate versions.
      # XXX Assumes versions from [epel-openstack-grizzly] > [base]
      action :upgrade

      # Force yum to search the openstack-grizzly repo.
      # FIXME(brett) Don't hardcode repo name (hardcoded in osops::packages).
      #   Maybe dynamically get name from `yum repolist'.
      options '--disablerepo="*" --enablerepo=epel-openstack-grizzly'

      # To protect ourselves from future chef runs, don't always upgrade
      # packages when updates are available (maybe consider checking
      # 'do_package_upgrades' though?).  Unfortunately the release versioning
      # convention isn't consistent across packages in this repo, so we can't
      # simply grep 'openstack' or similar.
      not_if "rpm -q --qf '%{RELEASE}\\n' #{pkg} |grep -E '\\.el6(ost|\\.gre)\\.'"
    end
  end
end
