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
recipe            "quantum-dhcp-agent", ""
recipe            "quantum-l3-agent", ""
recipe            "quantum-ovs-plugin", ""
recipe            "quantum-plugin", ""
recipe            "quantum-server", ""
recipe            "rpcdaemon", ""

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ mysql nova osops-utils sysctl apache2 apt yum}.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.20"
