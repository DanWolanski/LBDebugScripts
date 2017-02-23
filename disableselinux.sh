# Script to setup network and hostname

sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux && cat /etc/sysconfig/selinux &> /dev/null

echo "New contents for /etc/sysconfig/selinux"
echo 
grep SELINUX= /etc/sysconfig/selinux
echo 
echo "Note- the server needs to reboot for this to take effect"
