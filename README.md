# Cyber Security
Repository for preparing lectures
- By default, the commands are executed as a root user.

## 1. Delete IPv6 protocol
### < Configuration >
```vim
vim /etc/sysctl.conf
```
- [ All hosts ]
>```vim
>net.ipv6.conf.all.disable_ipv6 = 1  
>net.ipv6.conf.default.disable_ipv6 = 1  
>net.ipv6.conf.lo.disable_ipv6 = 1
>```
- [ fw01 ]
>```vim
>net.ipv4.ip_forward = 1  
>```
```vim
sysctl -p
```
### < Checking >
```vim
ip addr | grep "inet6"
```

## 2. Change the hostname & IPv4 Address settings
### < Configuration >
* Hostname (All hosts)
```vim
hostnamectl set-hostname <Hostname to change>
cat /etc/hostname
sed -i "s/<Original hostname>/<Hostname to change>/g" /etc/hosts
```
* IPv4 Address (All hosts)
```vim
mv /etc/netplan/*.yaml /etc/netplan/config.yaml   ### 채점기준에 요구되는 파일명으로 변경
ip addr show   ### Check your device name (ens33 ~ 4 . . . | vmware)
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
```bash
netplan apply
```
### < Checking >
```vim
hostname
ip addr | grep "global"
route -n4 | grep "G"
```

## 3. Service configuration & System security

## &nbsp; 1) SSH Connection security.
### < Configuration >
```vim
apt install -y ssh
```
```vim
vim /etc/ssh/sshd_config
```
>- [ All servers ]
>```vim
>Port 22312
>PermitRootLogin no
>```
>- [ web01, web02 ]
>```vim
>AllowUsers webadmin@10.10.10.10
>```
>- [ db01 ]
>```vim
>AllowUsers dbadmin@10.10.10.10
>```
>- [ lb01 ]
>```vim
>AllowUsers lbadmin@10.10.10.10
>```
>- [ fw01 ]
>```vim
>AllowUsers fwadmin@10.10.10.10
>```
```bash
systemctl restart sshd
```
### < Checking >
- [ client01 ]
```vim
ssh -p 22312 (web,db,lb,fw)admin@(db01,lb01,fw01,web01~2_address)
```
> ![Image](https://github.com/NullBins/CyberSecurity/blob/main/Images/SSH.png)

## &nbsp; 2) User permission management.
### < Configuration >
- Password policy
```vim
apt install -y libpam-pwquality
```
```vim
vim /etc/pam.d/common-password
```
>```vim
># here are the per-package modules (the "Primary" block)
>password     [success=1 default=ignore]     pam_unix.so obscure yescrypt
>password     requisite                      pam_pwquality.so retry=5 minlen=8 minclass=3
>```
- Sudo privilege
```vim
echo -e "customer12!@#\ncustomer12!@#" | adduser --gecos "" --uid 1000 customer
chmod +w /etc/sudoers
```
```vim
vim /etc/sudoers
```
>```vim
># User privilege specification
>root   ALL=(ALL:ALL) ALL
>customer   ALL=(ALL:ALL) ALL
>```
```vim
chmod -w /etc/sudoers
```
### < Checking >
- [ Any server ]
```bash
login customer
sudo whoami
```

## &nbsp; 3) Firewall settings.
### < Configuration >
### < Checking >

## &nbsp; 4) Web server security settings.
### < Configuration >
### < Checking >

## &nbsp; 5) DB server security settings.
### < Configuration >
### < Checking >

## 4. Load-Balancing configuration

## 5. DNS configuration
