maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.16"
recipe		  "network", ""

%w{ ubuntu fedora redhat centos }.each do |os|
	  supports os
end

%w{ apt cinder database dsh glance keystone monitoring mysql openssh rabbitmq selinux osops-utils sysctl yum }.each do |dep|
	  depends dep
end

