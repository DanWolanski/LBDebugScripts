# Script to setup network and hostname

# Defines
myHostName=$(hostname)
myFQDN=""
if [ $# -eq 1 ]; then
	myHostName=$1
fi
if [ $# -eq 2 ]; then
	myHostName=$1
        myFQDN=$2
fi
# Update the Hostname and /etc/hosts
# Replacing whole hosts file here, maybe appending is better, but easier to just set it to known entity to avoid any issues
# however, based on the finial sed there may be some
cat << __EOF > /etc/hosts
127.0.0.1   ${myHostName} ${myFQDN} localhost
::1	    ${myHostName} ${myFQDN} localhost
__EOF

#updating the hostname to BASE adress

echo "${myHostName}" > /etc/hostname

echo "/etc/hostname set to:"
cat /etc/hostname
echo
echo "/etc/hosts:"
cat /etc/hosts
echo
