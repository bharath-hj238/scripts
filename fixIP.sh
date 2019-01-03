#!/bin/bash

_IPADDRESS_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_ip_0|awk -F "value=" '{print $2}'|cut -d"\"" -f2)
_HOSTNAME_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_computerName|awk -F "value=" '{print $2}'|cut -d"\"" -f2)
_GATEWAY_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_gateway_0|awk -F "value=" '{print $2}'|cut -d"\"" -f2)
_DNS1_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_dns1_0|awk -F "value=" '{print $2}'|cut -d"\"" -f2)
_DNS2_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_dns2_0|awk -F "value=" '{print $2}'|cut -d"\"" -f2)
_NETMASK_=$(vmtoolsd --cmd "info-get guestinfo.ovfenv"|grep vCloud_netmask_0|awk -F "value=" '{print $2}'|cut -d"\"" -f2)

grep $_IPADDRESS_ /etc/sysconfig/network-scripts/ifcfg-eth0 && exit 0

cat > /etc/sysconfig/network <<EOF
NETWORKING=yes
NETWORKING_IPV6=no
HOSTNAME=$_HOSTNAME_
GATEWAY=$_GATEWAY_
DNS1=$_DNS1_
DNS2=$_DNS2_
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=$_IPADDRESS_
NETMASK=$_NETMASK_
EOF

cat > /etc/hostname <<EOF
$_HOSTNAME_
EOF

reboot
