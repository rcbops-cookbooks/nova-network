# Cookbook Name:: nova-network
# Recipe:: setup
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
# Public interface needs to be the bridge if the public interface is in the bridge
if node["nova"]["networks"][0]["bridge_dev"] == node["nova"]["network"]["public_interface"]
    node.set["nova"]["network"]["public_interface"] = node["nova"]["networks"][0]["bridge"]
end

node["nova"]["networks"].each do |net|
    nova_network_networks "Creating #{net['label']}" do
       label net['label']
       multi_host true
       fixed_range net['ipv4_cidr']
       num_networks net['num_networks']
       net_size net['network_size']
       bridge net['bridge']
       bridge_int net['bridge_dev']
       dns1 net['dns1']
       dns2 net['dns2']
       action :create_fixed
    end
end

# nova_network_networks "create floating ip network" do
    # pool node["nova"]["network"]["floating_pool_name"]
    # float_range node["nova"]["network"]["floating"]["ipv4_cidr"]
    # action :create_floating
    # only_if { node["nova"]["network"].has_key?(:floating) and node["nova"]["network"]["floating"].has_key?(:ipv4_cidr) }
# end
