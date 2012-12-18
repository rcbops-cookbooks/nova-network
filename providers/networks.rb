# Cookbook Name:: nova-network
# Provider:: networks
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
action :create_fixed do
    log "Creating network #{new_resource.label}"

    execute "nova-manage network create --label=#{new_resource.label}" do
	    command "nova-manage network create --multi_host=#{new_resource.multi_host} --label=#{new_resource.label} --fixed_range_v4=#{new_resource.fixed_range} --num_networks=#{new_resource.num_networks} --network_size=#{new_resource.net_size} --bridge=#{new_resource.bridge} --bridge_interface=#{new_resource.bridge_int} --dns1=#{new_resource.dns1} --dns2=#{new_resource.dns2}"
	    action :run
	    not_if "nova-manage network list | grep #{new_resource.fixed_range}"
    end
end

action :create_floating do
    log "Creating floating ip network"

    execute "nova-manage floating create" do
	    command "nova-manage floating create --pool=#{new_resource.pool} --ip_range=#{new_resource.float_range}"
	    action :run
	    only_if "nova-manage floating list | grep \"No floating IP addresses have been defined\""
    end
end
