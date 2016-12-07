#!/bin/bash
#author:shanker
#date:2012/4/12
#install ntp service
yum -y install ntp
cp -p /etc/ntp.conf /etc/ntp.conf.bak
cat > /etc/ntp.conf <<EOF
driftfile /var/lib/ntp/drift
restrict default ignore
restrict 127.0.0.1
restrict 192.168.0.0 mask 255.255.255.0 nomodify
server time.microsoft.com
restrict 192.168.0.1
server  127.127.1.0     # local clock
fudge   127.127.1.0 stratum 8
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF
service ntpd start

