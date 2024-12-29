# 🔐 사이버보안 *Cyber Security* 🛡
###### Repository for preparing lectures [ *Written by NullBins* ]
- By default, the commands are executed as a root user.

# [ *Project-1, 2023* ] <*Infrastructure configuration & Security enhancements*>

## 0. 호스트 네트워크 설정 (Host network settings)
### < *Configuration* >
- [ ns ] - Windows Server (PowerShell)
```powershell
Get-NetAdapter  # Interface index number (ex.10)
New-NetIPAddress -IPAddress "172.20.200.102" -PrefixLength 26 -InterfaceIndex 10 -DefaultGateway 172.20.200.65
Set-DnsClientServerAddress -InterfaceIndex 10 -ServerAddresses "172.20.200.102"
Rename-Computer -NewName "ns" -Restart -Force
$AdminAccount = Get-LocalUser -Name Administrator
Rename-LocalUser -InputObject $AdminAccount -NewName "cyber"
```
### < *Checking* >
- [ ns ]
```powershell
ipconfig -all
```

## 1. NAT 서비스 구성 (NAT Service configuration)
### < *Configuration* >
- [ fw ] - PAT
```vim
updata-alternative --set iptables /usr/sbin/iptables-legacy
```
```vim
vim /etc/rc.local
```
>```vim
>#!/bin/bash
>
>### DELETE
>iptables -t nat -D POSTROUTING 1
>
>### NAT
>iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE
>
>exit 0
>```
```vim
chmod +x /etc/rc.local
systemctl restart rc-local
```
- [ rt ] - PAT
```vim
updata-alternative --set iptables /usr/sbin/iptables-legacy
```
```vim
vim /etc/rc.local
```
>```vim
>#!/bin/bash
>
>### DELETE
>iptables -t nat -D POSTROUTING 1
>
>### NAT
>iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
>
>exit 0
>```
```vim
chmod +x /etc/rc.local
systemctl restart rc-local
```
### < *Checking* >
- [ fw, rt ]
```vim
iptables -t nat -L -v
```

## 2. DHCP 서비스 구성 (DHCP Service configuration)
### < *Configuration* >
- [ dlp ] - INSIDE (sales-01)
```vim
apt install -y isc-dhcp-server
```
```vim
vim /etc/default/isc-dhcp-server
```
>```vim
>INTERFACESv4="ens33"
>#INTERFACESv6=""
>```
```vim
vim /etc/dhcp/dhcpd.conf
```
>```vim
>subnet 10.10.10.0 netmask 255.255.254.0 {
>range 10.10.10.2 10.10.10.255;
>option routers 10.10.10.1;
>option domain-name "nicekorea.com";
>option domain-name-servers 172.20.200.102;
>default-lease-time 600;
>max-lease-time 7200;
>}
>
>subnet 172.20.200.64 netmask 255.255.255.192 {
>}
>```
```vim
systemctl restart isc-dhcp-server
```
- [ ex-ns ] - INSIDE (sales-02)
```vim
apt install -y isc-dhcp-server
```
```vim
vim /etc/default/isc-dhcp-server
```
>```vim
>INTERFACESv4="ens33"
>#INTERFACESv6=""
>```
```vim
vim /etc/dhcp/dhcpd.conf
```
>```vim
>subnet 10.10.10.0 netmask 255.255.255.0 {
>range 10.10.10.192 10.10.10.254;
>option routers 10.10.10.1;
>option domain-name "global.com";
>option domain-name-servers 201.10.20.2;
>default-lease-time 600;
>max-lease-time 7200;
>}
>
>subnet 201.10.20.0 netmask 255.255.255.248 {
>}
>```
```vim
systemctl restart isc-dhcp-server
```
- [ fw ] - DHCP Relay
```vim
apt install -y isc-dhcp-relay
```
```vim
vim /etc/default/isc-dhcp-relay
```
>```vim
>SERVERS="172.20.200.101"
>```
```vim
systemctl restart isc-dhcp-relay
```
- [ rt ] - DHCP Relay
```vim
apt install -y isc-dhcp-relay
```
```vim
vim /etc/default/isc-dhcp-relay
```
>```vim
>SERVERS="201.10.20.2"
>```
```vim
systemctl restart isc-dhcp-relay
```
### < *Checking* >
- [ dlp, ex-ns ]
```vim
dhcp-lease-list
```

## 3. AD 도메인 구성 및 DNS 설정 (Active Directory Domain configuration & DNS settings)
### < *Configuration* >
- [ ns ] - Active Directory Domain Controller
```powershell
Install-WindowsFeature ad-domain-services -IncludeManagementTools
$PW = ConvertTo-SecureString -String "Cyber2023\$\$" -AsPlainText -Force
Install-ADDSForest -DomainName nicekorea.com -SafeModeAdministratorPassword $PW -DomainMode 7 -ForestMode 7 -Force
New-ADOrganizationalUnit -Name Sales
New-ADOrganizationalUnit -Name Managers
New-ADOrganizationalUnit -Name Webs
New-ADGroup -GroupScope Global Sales -Path "ou=Sales,dc=nicekorea,dc=com"
New-ADGroup -GroupScope Global Managers -Path "ou=Managers,dc=nicekorea,dc=com"
New-ADGroup -GroupScope Global Webs -Path "ou=Webs,dc=nicekorea,dc=com"
dsadd user cn=kim,ou=sales,dc=nicekorea,dc=com -pwd Cyber2023\$\$ -memberof cn=sales,ou=sales,dc=nicekorea,dc=com
dsadd user cn=park,ou=sales,dc=nicekorea,dc=com -pwd Cyber2023\$\$ -memberof cn=sales,ou=sales,dc=nicekorea,dc=com
dsadd user cn=mgr01,ou=managers,dc=nicekorea,dc=com -pwd Cyber2023\$\$ -memberof cn=managers,ou=managers,dc=nicekorea,dc=com
dsadd user cn=mgr02,ou=managers,dc=nicekorea,dc=com -pwd Cyber2023\$\$ -memberof cn=managers,ou=managers,dc=nicekorea,dc=com
dsadd user cn=webadmin,ou=webs,dc=nicekorea,dc=com -pwd Cyber2023\$\$ -memberof cn=webs,ou=webs,dc=nicekorea,dc=com
```
- [ www1, www2 ] - Join AD Domain
```vim
apt install -y krb5-user samba-common-bin sssd realmd sssd-tools adcli
 1) NICEKOREA.COM
 2) ns.nicekorea.com
 3) ns.nicekorea.com
realm discover nicekorea.com
realm join --user=cyber nicekorea.com
systemctl start sssd
systemctl enable sssd
```
- [ ns ] - Add DNS Record
```powershell
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name www -IPv4Address 172.20.200.101
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name intra -IPv4Address 172.20.200.101
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name shop -IPv4Address 172.20.200.101
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name dlp -IPv4Address 172.20.200.101
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name smtp -IPv4Address 172.20.200.103
Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name imap -IPv4Address 172.20.200.103
```
### < *Checking* >
- [ ns ]
```powershell
dsa.msc
```
- [ www1 ]
```vim
id kim@nicekorea.com
```
