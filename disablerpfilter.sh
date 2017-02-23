# Script to setup network and hostname

#setup the rp_filter on the interfaces
cp /etc/sysctl.conf /etc/sysctl.conf.bak
sysctl -A | grep .rp_filter >> /etc/sysctl.conf 

sed -i 's/rp_filter = 1/rp_filter = 0/g' /etc/sysctl.conf 

awk '!x[$0]++' /etc/sysctl.conf  > /etc/sysctl.conf.uniq
mv /etc/sysctl.conf.uniq /etc/sysctl.conf
sysctl -f /etc/sysctl.conf &> /dev/null
#restarteing both here to cover bases depending what version is installed
systemctl restart network
service network restart

#performing ip a so that we can configure
ip a
echo
echo rp_filter from sysctl
sysctl -a | grep .rp_filter
echo
