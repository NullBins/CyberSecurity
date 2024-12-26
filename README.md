# Cyber Security
Repository for preparing lectures (Ubuntu)

## 1. Delete IPv6 Protocol (All hosts)
### < Configuration >
```vim
vim /etc/sysctl.conf
```
>```vim
>net.ipv6.conf.all.disable_ipv6 = 1  
>net.ipv6.conf.default.disable_ipv6 = 1  
>net.ipv6.conf.lo.disable_ipv6 = 1
>```
```vim
sysctl -p
```
### < Checking >
```vim
ip addr | grep inet6
```

## 2. Change the hostname & IPv4 Address settings
### < Configuration >
* Hostname (All hosts)
```vim
hostnamectl set-hostname <hostname>
cat /etc/hostname
```
* IPv4 (All hosts)
```vim
mv /etc/netplan/*.yaml /etc/netplan/config.yaml
ip addr show   ### Check device name (ens33 ~ 4 . . . | vmware)
```
```vim
vim /etc/netplan/config.yaml
```
>```yaml
>networks:
>  ethernets:
>    ens33:
>      addresses: [10.10.10.12/24]
>      gateway4: 10.10.10.1
>      nameservers:
>        addresses: [10.10.10.1]
>      dhcp4: false
>  version: 2
>```
```vim
netplan apply
```

### < Checking >
```vim
ip addr | grep "global"
route -n4 | grep "G"
```
