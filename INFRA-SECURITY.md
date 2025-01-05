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
dsadd user cn=kim,ou=sales,dc=nicekorea,dc=com -pwd 'Cyber2023$$' -memberof cn=sales,ou=sales,dc=nicekorea,dc=com
dsadd user cn=park,ou=sales,dc=nicekorea,dc=com -pwd 'Cyber2023$$' -memberof cn=sales,ou=sales,dc=nicekorea,dc=com
dsadd user cn=mgr01,ou=managers,dc=nicekorea,dc=com -pwd 'Cyber2023$$' -memberof cn=managers,ou=managers,dc=nicekorea,dc=com
dsadd user cn=mgr02,ou=managers,dc=nicekorea,dc=com -pwd 'Cyber2023$$' -memberof cn=managers,ou=managers,dc=nicekorea,dc=com
dsadd user cn=webadmin,ou=webs,dc=nicekorea,dc=com -pwd 'Cyber2023$$' -memberof cn=webs,ou=webs,dc=nicekorea,dc=com
```
- [ www1, www2 ] - Join AD Domain
```vim
apt install -y realmd sssd sssd-tools adcli krb5-user packagekit samba-common-bin
 1) NICEKOREA.COM
 2) ns.nicekorea.com
 3) ns.nicekorea.com
```
```vim
vim /etc/krb5.conf
```
>```vim
>[libdefaults]
>    default_realm = NICEKOREA.COM
>    dns_lookup_realm = false
>    dns_lookup_kdc = true
>
>[realms]
>    NICEKOREA.COM = {
>        kdc = ns.nicekorea.com
>        admin_server = ns.nicekorea.com
>    }
>
>[domain_realm]
>    .nicekorea.com = NICEKOREA.COM
>    nicekorea.com = NICEKOREA.COM
>```
```vim
realm discover nicekorea.com
realm join --user=cyber nicekorea.com
systemctl start sssd
systemctl enable sssd
echo -e "session optional pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session
pam-auth-update
```
- [ ns ] - Add DNS Record
```powershell
"www","intra","shop","dlp" | %{Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name $_ -IPv4Address 172.20.200.101}
"smtp","imap" | %{Add-DnsServerResourceRecord -A -ZoneName nicekorea.com -Name $_ -IPv4Address 172.20.200.103}
Add-DnsServerResourceRecord -MX -ZoneName nicekorea.com -Name "." -MailExchange "smtp.nicekorea.com" -Preference 10
Add-DnsServerResourceRecord -MX -ZoneName nicekorea.com -Name "." -MailExchange "imap.nicekorea.com" -Preference 10
```
- [ ex-ns ]
```vim
apt install -y bind9
```
```vim
vim /etc/bind/named.conf
```
>```vim
>#include "/etc/bind/named.conf.options";
>#include "/etc/bind/named.conf.local";
>#include "/etc/bind/named.conf.default-zones";
>
>options {
> directory "/var/cache/bind";
> listen-on { any; };
> allow-query { any; };
> recursion no;
> dnssec-validation no;
>};
>
>zone "global.com" {
> type master;
> file "db.global.com";
>};
>
>zone "nicekorea.com" {
> type master;
> file "db.nicekorea.com";
>};
>```
```vim
cp /etc/bind/db.0 /var/cache/bind/db.global.com
cp /etc/bind/db.0 /var/cache/bind/db.nicekorea.com
chown bind:bind -R /var/cache/bind/
sed -i "s/localhost/global.com/g" /var/cache/bind/db.global.com
sed -i "s/localhost/nicekorea.com/g" /var/cache/bind/db.nicekorea.com
```
```vim
vim /var/cache/bind/db.global.com
```
>```vim
>@   IN   NS   dns.global.com
>ex-ns   IN   A   201.10.20.2
>dns   IN   A   201.10.20.2
>```
```vim
vim /var/cache/bind/db.nicekorea.com
```
>```vim
>@   IN   NS   global.com
>@   IN   A   201.10.20.2
>vpn   IN   A   201.10.10.1
>security   IN   A   201.10.10.1
>```
```vim
systemctl restart bind9
```
### < *Checking* >
- [ ns ]
```powershell
dsa.msc
```
- [ www1 ]
```vim
id kim@nicekorea.com
groups kim@nicekorea.com
login kim@nicekorea.com
```

## 4. Web 서비스 및 프록시 구성 (Web service & Proxy configuration)
### < *Configuration* >
- [ www1, www2 ]
```vim
apt install -y apache2 libapache2-mod-auth-kerb
```
```vim
a2dissite 000-default.conf
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/www.conf
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/intra.conf
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/shop.conf
```
```vim
vim /etc/apache2/posts.conf
```
>```vim
>Listen 8888
>Listen 9000
>Listen 9090
>```
```vim
vim /etc/apache2/sites-available/www.conf
```
>```vim
><VirtualHost *:9000>
> ServerName www.nicekorea.com
> DocumentRoot /var/www/html/main
></VirtualHost>
>```
```vim
vim /etc/apache2/sites-available/shop.conf
```
>```vim
><VirtualHost *:8888>
> ServerName shop.nicekorea.com
> DocumentRoot /var/www/html/shop
></VirtualHost>
>```
```vim
vim /etc/apache2/sites-available/intra.conf
```
>```vim
><VirtualHost *:9090>
> ServerName intra.nicekorea.com
> DocumentRoot /var/www/html/intra
> <Directory /var/www/html/intra>
>  AuthType Kerberos
>  AuthName "Kerberos Authentication"
>  Krb5KeyTab /etc/krb5.keytab
>  KrbAuthRealms NICEKOREA.COM
>  KrbServiceName HTTP/intra.nicekorea.com@NICEKOREA.COM
>  KrbVerifyKDC off
> </Directory>
> LogLevel auth_kerb:debug
></VirtualHost>
>```
```vim
mkdir -p /var/www/html/{main,intra,shop}
echo -e "사내 게시판 입니다." > /var/www/html/intra/index.html
echo -e "nicekorea.com 입니다." > /var/www/html/main/index.html
echo -e "shop 페이지 입니다." > /var/www/html/shop/index.html
a2ensite www.conf
a2ensite intra.conf
a2ensite shop.conf
systemctl restart apache2
```
- [ dlp ]
```vim
apt install -y haproxy
```
```vim
vim /etc/haproxy/haproxy.cfg
```
>```vim
>frontend front_www
> bind *:9000
> default_backend back_www
>
>backend back_www
> server www1 172.20.200.103:9000 check
> server www2 172.20.200.104:9000 check
>
>frontend front_intra
> bind *:9090
> default_backend back_intra
>
>backend back_intra
> server www1 172.20.200.103:9090 check
> server www2 172.20.200.104:9090 check
>
>frontend front_shop
> bind *:8888
> default_backend back_shop
>
>backend back_intra
> server www1 172.20.200.103:8888 check
> server www2 172.20.200.104:8888 check
>```
```vim
systemctl restart haproxy
```
