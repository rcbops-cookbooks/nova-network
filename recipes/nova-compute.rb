#
# Cookbook Name:: nova-network
# Recipe:: nova-compute
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node["nova"]["network"]["provider"] == "quantum"
	include_recipe "nova-network::quantum-plugin"
else
	include_recipe "nova-network::nova-network"
end
