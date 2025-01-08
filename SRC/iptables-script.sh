#!/bin/bash

### LEGACY
update-alternatives --set iptables /usr/sbin/iptables-legacy

### FW
iptables -A INPUT -p tcp --dport 22312 -j DROP
iptables -A INPUT -s 10.10.10.10/32 -p tcp --dport 22312 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i ens33(eth0) -o ens34(eth1) -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ens34 -o ens33 -j ACCEPT

### NAT
iptables -t nat -A POSTROUTING -o ens34(eth1) -j MASQUERADE
