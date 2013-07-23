from quantum.openstack.common import log as logging
from quantum.common import config

logging.setup('quantum')
config.parse(['--config-file', '/etc/quantum/quantum.conf', '--config-file', '/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini'])
application = config.load_paste_app("quantum")
