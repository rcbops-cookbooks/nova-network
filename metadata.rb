maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures the networking required for Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.19"
recipe            "nova-compute", ""
recipe            "nova-controller", ""
recipe            "nova-network", ""
recipe            "nova-setup", ""
recipe            "quantum-dhcp-agent", ""
recipe            "quantum-l3-agent", ""
recipe            "quantum-ovs-plugin", ""
recipe            "quantum-plugin", ""
recipe            "quantum-server", ""

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ mysql monitoring nova osops-utils sysctl }.each do |dep|
  depends dep
end
