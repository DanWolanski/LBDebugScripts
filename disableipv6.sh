#Diable the IPv6 on the interfaces
cp /etc/sysctl.conf /etc/sysctl.conf.bak.ipv6

sysctl -A | grep net.ipv6 >> /etc/sysctl.conf 

sed -i 's/disable_ipv6 = ./disable_ipv6 = 1/g' /etc/sysctl.conf 

awk '!x[$0]++' /etc/sysctl.conf  > /etc/sysctl.conf.uniq
mv /etc/sysctl.conf.uniq /etc/sysctl.conf
sysctl -f /etc/sysctl.conf &> /dev/null
#restarteing both here to cover bases depending what version is installed
systemctl restart network
service network restart

#performing ip a so that we can configure
echo disable_ipv6 from sysctl
echo
ip a
echo
sysctl -a | grep disable_ipv6
echo
