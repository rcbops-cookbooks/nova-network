# Cookbook Name:: nova-network
# Recipe:: neutron-plugin
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

case node["neutron"]["plugin"]
when "ovs"
  include_recipe "nova-network::neutron-ovs-plugin"
end

# This should be better however getting the DB stamped as the release in a RHEL
# System seems to be impossible without some hackyness, thus here is the hack.
# TODO(cloudnull) if we continue with these cookbooks this should be better...
plugin_count = get_nodes_by_recipe("nova-network::neutron-plugin").length

if plugin_count <= 1
  # Get stamp hash
  stamp = node["neutron"]["db"]["stamp"]

  # Add a revision
  execute 'add_revision' do
    command "neutron-db-manage revision -m 'RCBOPS Deployment #{stamp["revision"]}'"
    action :nothing
  end

  # Stamp the DB
  execute 'stamp_db' do
    command "neutron-db-manage --config-file #{stamp["config"]} --config-file #{stamp["plugin"]} stamp #{stamp["revision"]}"
    action :run
    not_if "neutron-db-manage history | grep \"RCBOPS Deployment #{stamp["revision"]}\""
    notifies :run, 'execute[add_revision]', :immediately
  end
end