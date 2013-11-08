maintainer        "Rackspace US, Inc."
name              "nova-network"
license           "Apache 2.0"
description       "Installs and configures the networking required for Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           IO.read(File.join(File.dirname(__FILE__), "VERSION"))
recipe            "nova-compute", ""
recipe            "nova-controller", ""
recipe            "nova-network", ""
recipe            "nova-setup", ""
recipe            "neutron-dhcp-agent", ""
recipe            "neutron-l3-agent", ""
recipe            "neutron-ovs-plugin", ""
recipe            "neutron-plugin", ""
recipe            "neutron-server", ""
recipe            "rpcdaemon", ""

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ mysql nova osops-utils sysctl apache2 }.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.20"
