#!/usr/bin/env bash

# Remove legacy resources
ovs-vsctl del-port patch_to_vswitch0
ovs-vsctl del-port patch_to_vswitch1

ovs-docker del-port vswitch0 eth0 vm1
ovs-docker del-port vswitch1 eth0 vm2
ovs-docker del-port vswitch0 eth0 vm3
ovs-docker del-port vswitch1 eth0 vm4

ovs-vsctl del-br vswitch0
ovs-vsctl del-br vswitch1

docker stop vm1 vm2 vm3 vm4
docker rm vm1 vm2 vm3 vm4

# Rebuld image
docker build . -t c7

##########

docker run -t -i -d --name vm1 --net=none --privileged c7 /bin/sh
docker run -t -i -d --name vm2 --net=none --privileged c7 /bin/sh
docker run -t -i -d --name vm3 --net=none --privileged c7 /bin/sh
docker run -t -i -d --name vm4 --net=none --privileged c7 /bin/sh


ovs-vsctl add-br vswitch0
ovs-vsctl add-br vswitch1


ovs-docker add-port vswitch0 eth0 vm1 --ipaddress=192.168.1.2/24
ovs-docker add-port vswitch1 eth0 vm2 --ipaddress=192.168.1.3/24
ovs-docker add-port vswitch0 eth0 vm3 --ipaddress=192.168.1.4/24
ovs-docker add-port vswitch1 eth0 vm4 --ipaddress=192.168.1.5/24


ovs-vsctl add-port vswitch0 patch_to_vswitch1
ovs-vsctl add-port vswitch1 patch_to_vswitch0
ovs-vsctl set interface patch_to_vswitch1 type=patch
ovs-vsctl set interface patch_to_vswitch0 type=patch
ovs-vsctl set interface patch_to_vswitch0 options:peer=patch_to_vswitch1
ovs-vsctl set interface patch_to_vswitch1 options:peer=patch_to_vswitch0

ovs-vsctl show

read -p "Please test ovs connection between instances..."
# Test case 1
## docker-enter vm1
## $ ping 192.168.1.3
## $ ping 192.168.1.4
## $ ping 192.168.1.5


vswitch0_ifs=$(ovs-vsctl list-ports vswitch0 | grep -v patch)
vswitch1_ifs=$(ovs-vsctl list-ports vswitch1 | grep -v patch)

for v0if in $vswitch0_ifs;do
    vm=$(ovs-vsctl list interface $v0if | grep external_ids | awk -F '"' '{print $2}')
    eval ${vm}_nic=$v0if
done

for v1if in $vswitch1_ifs;do
    vm=$(ovs-vsctl list interface $v1if | grep external_ids | awk -F '"' '{print $2}')
    eval ${vm}_nic=$v1if
done

echo "vm1 interface is $vm1_nic"
echo "vm2 interface is $vm2_nic"
echo "vm3 interface is $vm3_nic"
echo "vm4 interface is $vm4_nic"


# Here variable vmx_nic came from 'eval' in upper scripts
ovs-vsctl set port $vm1_nic tag=100
ovs-vsctl set port $vm2_nic tag=100
ovs-vsctl set port $vm3_nic tag=200
ovs-vsctl set port $vm4_nic tag=200


read -p "Please test ovs connection between instances..."
# Test case 2
## docker-enter vm1
## $ ping 192.168.1.3   # vm2
## $ ping 192.168.1.4   # vm3

## docker-enter vm3
## $ ping 192.168.1.3   # vm2
## $ ping 192.168.1.5   # vm4


ovs-vsctl set port patch_to_vswitch1 VLAN_mode=trunk
ovs-vsctl set port patch_to_vswitch0 VLAN_mode=trunk

ovs-vsctl set port patch_to_vswitch0 trunk=100
ovs-vsctl set port patch_to_vswitch1 trunk=100

 
read -p "Please test ovs connection between instances..."
# Test case 3
## docker-enter vm1
## $ ping 192.168.1.3   # vm2

## docker-enter vm3
## $ ping 192.168.1.5   # vm4



