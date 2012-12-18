action :create_fixed do
    log "Creating network #{new_resource.label}"

    execute "nova-manage network create --label=#{new_resource.label}" do
	    command "nova-manage network create --multi_host=#{new_resource.multi_host} --label=#{new_resource.label} --fixed_range_v4=#{new_resource.fixed_range} --num_networks=#{new_resource.num_networks} --network_size=#{new_resource.net_size} --bridge=#{new_resource.bridge} --bridge_interface=#{new_resource.bridge_int} --dns1=#{new_resource.dns1} --dns2=#{new_resource.dns2}"
	    action :run
	    not_if "nova-manage network list | grep #{new_resource.fixed_range}"
    end
end

action :create_floating do
    log "Creating floating ip network"

    execute "nova-manage floating create" do
	    command "nova-manage floating create --pool=#{new_resource.pool} --ip_range=#{new_resource.float_range}"
	    action :run
	    only_if "nova-manage floating list | grep \"No floating IP addresses have been defined\""
    end
end
