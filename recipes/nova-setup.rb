# Cookbook Name:: nova-network
# Recipe:: setup
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
# Public interface needs to be the bridge if the public interface is in the bridge
if node["nova"]["networks"]["public"]["bridge_dev"] ==
  node["nova"]["network"]["public_interface"]
  node.set["nova"]["network"]["public_interface"] =
    node["nova"]["networks"]["public"]["bridge"]
end

node["nova"]["networks"].each do |net, v|
  nova_network_networks "Creating #{v['label']}" do
    label v['label']
    multi_host true
    fixed_range v['ipv4_cidr']
    bridge v['bridge']
    bridge_int v['bridge_dev']
    dns1 v['dns1']
    dns2 v['dns2']
    if v.has_key?('vlan_id')
      Chef::Log.debug "Vlan ID set #{v['vlan_id']}"
      vlan_id v['vlan_id']
    end
    action :create_fixed
  end
end
