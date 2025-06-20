# 🔐 사이버보안 *Cyber Security* 🛡
###### 📚 Repository for preparing lectures [ *Written by NullBins* ]
- By default, the commands are executed as a root user.

# [ *Project-1* ] <*Infrastructure configuration & Security enhancements*>

## 1. IPv6 프로토콜 제거 (Disable IPv6 protocol)
### < *Configuration* >
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
### < *Checking* >
```vim
ip -6 addr show | grep "inet6"
```

## 2. 호스트명 변경 및 IP 설정 (Change the hostname & IPv4 Address settings)
### < *Configuration* >
* Hostname (All hosts)
```vim
hostnamectl set-hostname <Hostname to change>
cat /etc/hostname
sed -i "s/<Original hostname>/<Hostname to change>/g" /etc/hosts
```
* IPv4 Address (All hosts)
```bash
mv /etc/netplan/*.yaml /etc/netplan/config.yaml   ### 채점기준에 요구되는 파일명으로 변경
ip link show   ### 인터페이스 확인 (ens33 ~ 4 . . . | VMware)
```
```vim
vim /etc/netplan/config.yaml
```
>```yaml
>network:
>  ethernets:
>    ens33:
>      addresses: [10.10.10.10/24]
>      gateway4: 10.10.10.1
>      nameservers:
>        addresses: [10.10.10.12]
>      dhcp4: false
>  version: 2
>```
```bash
netplan apply
```
### < *Checking* >
```vim
hostname
ip -4 addr show | grep "global"
route -n4 | grep "G"
```

## 3. 서비스 구성 및 시스템 보안 (Service configuration & System security)

## &nbsp; 1) SSH 연결 보안 [SSH Connection security.]
### < *Configuration* >
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
### < *Checking* >
- [ client01 ]
```vim
ssh -p 22312 (web,db,lb,fw)admin@(db01,lb01,fw01,web01~2_address)
```
> ![Image](https://github.com/NullBins/CyberSecurity/blob/main/IMAGES/SSH.png)

## &nbsp; 2) 사용자 및 권한 관리 [User permission management.]
### < *Configuration* >
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
echo -e "customer12!@#\ncustomer12!@#" | adduser --gecos "" --uid 1001 customer
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
### < *Checking* >
- [ Any server ]
```bash
login customer
sudo whoami
```

## &nbsp; 3) 방화벽 설정 [Firewall settings.]
### < *Configuration* >
- [ fw01 ]
```vim
apt install -y iptables-persistent
```
- FW settings
```vim
iptables -A INPUT -p tcp --dport 22312 -j DROP
iptables -A INPUT -s 10.10.10.10/32 -p tcp --dport 22312 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i ens33 -o ens34 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ens34 -o ens33 -j ACCEPT
```
- NAT settings
```vim
iptables -t nat -A POSTROUTING -o ens34 -j MASQUERADE
```
- Save settings
```vim
iptables-save > /etc/iptables/rules.v4
```
### < *Checking* >
- [ fw01 ]
```vim
iptables -L -v
iptables -t nat -L -v
```

## &nbsp; 4) 웹 서버 보안 설정 [Web server security settings.]
### < *Configuration* >
- [ web01, web02 ]
```vim
apt install -y apache2
```
- Disable unnecessary module
```bash
a2dismod autoindex
: Yes, do as I say!   ### 이거 입력해야 비활성화 됨;;
a2dismod negotiation
: Yes, do as I say!   ### 응, 내 말대로 해!
```
- No access to parent directory
```vim
vim /etc/apache2/apache2.conf
```
>```vim
><Directory /var/www/>
>  Options -Indexes
>  AllowOverride None
>  Require all granted
></Directory>
>```
- Add security headers
```vim
vim /etc/apache2/sites-available/000-default.conf
```
>```vim
><VirtualHost: *:80>
>  Header always set X-Content-Type-Options "nosniff"
>  Header always set X-Frame-Options "DENY"
>  Header always set Content-Security-Policy "default-src 'self';"
></VirtualHost>
>```
```vim
a2enmod headers
systemctl restart apache2
```
### < *Checking* >
```vim
apache2ctl -M | grep –E "autoindex|negotiation"
```

## &nbsp; 5) 데이터베이스 서버 보안 설정 [DB server security settings.]
### < *Configuration* >
- [ db01 ]
```vim
apt install -y postgresql
```
```vim
vim /etc/postgresql/<version>/main/pg_hba.conf
```
>```vim
>host  all    all    10.10.30.10/24    scram-sha-256
>host  all    all    10.10.30.11/24    scram-sha-256
>```
```vim
vim /etc/postgresql/<version>/main/postgresql.conf
```
>```vim
># - Connection Settings -
>listen_addresses = '*'
>
># - Shared Library Preloading -
>shared_preload_libraries = '$libdir/passwordcheck'   # change requires restart
>```
```vim
systemctl restart postgresql
sudo -iu postgres
psql
```
```sql
postgres=# CREATE DATABASE account_info;
postgres=# CREATE TABLE account( id SERIAL PRIMARY KEY, username VARCHAR(255) NOT NULL, password VARCHAR(255) NOT NULL );
postgres=# CREATE USER dbadmin WITH PASSWORD 'admin12!@#' SUPERUSER;
postgres=# ALTER DATABASE account_info OWNER TO dbadmin;
```
### < *Checking* >
- [ web01 ]
```vim
psql –h 10.10.30.12 –U dbadmin –W –d account_info
account_info=# SELECT * FROM account;
```

## 4. 로드밸런싱 구성 (Load-Balancing configuration)
### < *Configuration* >
- [ lb01 ] Round Robin
```vim
apt install -y haproxy
```
```vim
vim /etc/haproxy/haproxy.cfg
```
>```vim
>frontend front_http
>  bind *:80
>  default_backend back_http
>backend back_http
>  balance roundrobin
>  server web01 10.10.30.10:80 check
>  server web02 10.10.30.11:80 check
>```
```vim
systemctl restart haproxy
```
### < *Checking* >
- [ client01 ] Firefox
> ![Image](https://github.com/NullBins/CyberSecurity/blob/main/IMAGES/Firefox_web.png)
```vim
lynx http://10.10.30.13
```

## 5. DNS 구성 (DNS configuration)
### < *Configuration* >
- [ dns01 ]
```vim
apt install -y bind9
```
```vim
vim /etc/bind/named.conf.local
```
>```vim
>zone "web-server.com" {
>  type master;
>  file "/etc/bind/db.web-server.com";
>};
>```
```vim
cp /etc/bind/db.local /etc/bind/db.web-server.com
chown bind:bind -R /etc/bind/
sed -i "s/localhost/web-server.com/g" /etc/bind/db.web-server.com
```
```vim
vim /etc/bind/db.web-server.com
```
>```vim
>@  IN  NS  ns.web-server.com.
>ns  IN  A  10.10.30.13
>lb01  IN  A  10.10.30.13
>web-server.com.  IN  A  10.10.30.13
>```
```vim
systemctl restart bind9
```
### < *Checking* >
- [ client01 ]
```vim
nslookup web-server.com
```
