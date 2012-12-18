actions :create_fixed, :create_floating

# nova-manage network create cli options
attribute :label, :kind_of => String
attribute :multi_host, :kind_of => [ TrueClass, FalseClass], :default => true
attribute :fixed_range, :kind_of => String
attribute :num_networks, :kind_of => Integer
attribute :net_size, :kind_of => Integer
attribute :bridge, :kind_of => String
attribute :bridge_int, :kind_of => String
attribute :dns1, :kind_of => String
attribute :dns2, :kind_of => String

# nova floating ips
attribute :pool, :kind_of => String
attribute :float_range, :kind_of => String
