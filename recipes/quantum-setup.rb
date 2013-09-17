#
# Cookbook Name:: nova-network
# Recipe:: quantum-server (API service)
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

# make sure we die early if there are quantum-setups other than us
if get_role_count("quantum-setup", false) > 0
  msg = "You can only have one node with the quantum-setup role"
  Chef::Application.fatal! msg
end

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"

platform_options = node["quantum"]["platform"]

quantum = get_settings_by_role("quantum-setup", "quantum")
if node["developer_mode"] == true
  node.set_unless["quantum"]["db"]["password"] = "quantum"
else
  node.set_unless["quantum"]["db"]["password"] = secure_password
  node.set_unless["quantum"]["service_pass"] = secure_password
  node.set_unless["quantum"]["quantum_metadata_proxy_shared_secret"] =
    secure_password
end

unless Chef::Config[:solo]
  node.save
end

# Only do this setup once the db/service pass has been set.
include_recipe "nova-network::quantum-common"

# Create db and user
# return connection info
# defined in osops-utils/libraries
mysql_info = create_db_and_user(
  "mysql",
  node["quantum"]["db"]["name"],
  node["quantum"]["db"]["username"],
  node["quantum"]["db"]["password"]
)

# Adds db Indexing for the hosts as found in the agents table.
# Defined in osops-utils/libraries

add_index_stopgap("mysql",
                  node["quantum"]["db"]["name"],
                  node["quantum"]["db"]["username"],
                  node["quantum"]["db"]["password"],
                  "rax_ix_host_index",
                  "agents",
                  "host",
                  "service[quantum-server]",
                  :run)
