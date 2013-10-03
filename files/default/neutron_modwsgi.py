from neutron.openstack.common import log as logging
from neutron.common import config

logging.setup('neutron')
config.parse(['--config-file', '/etc/neutron/neutron.conf', '--config-file', '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini'])
application = config.load_paste_app("neutron")
