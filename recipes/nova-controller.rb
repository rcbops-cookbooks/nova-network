#
# Cookbook Name:: nova-network
# Recipe:: nova-controller
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node["nova"]["network"]["provider"] == "quantum"
	include_recipe "nova-network::quantum-server"
else
	include_recipe "nova-network::nova-network"
	include_recipe "nova-network::nova-setup"
end
