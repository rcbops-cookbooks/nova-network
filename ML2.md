james.denton@rackspace.com
July 18, 2014

Attributes
==========

Neutron Networking w/ ML2 & LinuxBridge
----

A new plugin attribute has been added. Valid options include ovs or ml2_linuxbridge.

A set of attributes for LinuxBridge have been added. It is not necessary to create a bridge manually; LinuxBridge does this for you. Simply specify the physical interface to use in the bridge.

```javascript

	  "plugin": "ml2_linuxbridge",
      "ml2_linuxbridge": {
        "provider_networks": [
          {
            "label": "ph-eth1",
            "bridge": "eth1",
            "vlans": ""
          }
        ],
        "network_type": "vlan",
        "external_bridge": ""
      }
```

There is no vxlan support.
