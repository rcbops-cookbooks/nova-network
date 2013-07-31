# Cookbook Name:: nova-network
# Resource:: networks
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
actions :create_fixed, :create_floating, :delete_fixed, :delete_floating

def initialize(*args)
  super
  @action = :create
end

# nova-manage network create cli options
attribute :label, :kind_of => String
attribute :multi_host, :kind_of => [TrueClass, FalseClass], :default => true
attribute :fixed_range, :kind_of => String
attribute :bridge, :kind_of => String
attribute :bridge_int, :kind_of => String
attribute :dns1, :kind_of => String
attribute :dns2, :kind_of => String
attribute :vlan_id, :kind_of => Integer

# nova floating ips
attribute :pool, :kind_of => String
attribute :float_range, :kind_of => String
