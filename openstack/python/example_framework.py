import openstack.config

conn = openstack.connect(cloud="openstack")

print "Servers:"
print conn.list_servers()

print "Image ID:"
imageufcqx = conn.get_image("Ubuntu1604UFCQX")['id']
print imageufcqx

print "Flavor:"
flavorufcqx = conn.get_flavor("ufcquixada")['id']; 
print flavorufcqx

print "Creating Server:"
server = conn.create_server(name="framework_teste", image=imageufcqx, 
                            flavor=flavorufcqx, network="private_network_computacaoemnuvem", 
			    key_name = "alunoufc", security_groups=["default"])
print server['id']
