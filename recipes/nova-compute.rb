#
# Cookbook Name:: nova-network
# Recipe:: nova-compute
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

if node["nova"]["network"]["provider"] == "neutron"
  include_recipe "nova-network::neutron-plugin"
  include_recipe "sysctl::default"

  sysctl 'net.ipv4.ip_forward' do
    value '1'
  end
else
  include_recipe "nova::api-metadata"
  include_recipe "nova-network::nova-network"
end
