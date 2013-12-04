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
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

# drop the config file
template "/etc/rpcdaemon.conf" do
  source "rpcdaemon.conf.erb"
  owner "root"
  group "neutron"
  mode "0640"
  variables(
    "rabbit_ipaddress" => rabbit_info["host"],
    "check_interval" => node["rpcdaemon"]["check_interval"],
    "queue_expire" => node["rpcdaemon"]["queue_expire"],
    "timeout" => node["rpcdaemon"]["timeout"]
  )
end

# install the rpc daemon package
package "rpcdaemon" do
  action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  options platform_options["package_options"]
end

# Ensure service is started and running.
service "rpcdaemon" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  subscribes :restart, "template[/etc/rpcdaemon.conf]", :delayed
end
