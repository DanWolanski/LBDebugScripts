#!/bin/bash
# This script will add the iptables rule for udp
#   it will also setup so it is run each time at start 
#   by placing them in the /etc/iptables/rules.v4
LOG=/dev/null
EXITONFAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
OFFSET='\033[60G'
echo_success(){
  echo -en \\033
  echo -en "${OFFSET}[  ${GREEN}OK${NC}  ]\n";
}
echo_failure(){
echo -en "${OFFSET}[${RED}FAILED${NC}]\n";
}
step() {
    echo -n -e "$@"
}
try (){
    "$@" &>> $LOG 
    if [[ $? -ne 0 ]] ; then 
	echo_failure  
     else 
	echo_success 
     fi
}

echo

step "Checking for iptables" 
try /usr/sbin/iptables -t raw --list

step "Adding UDP rule"
try iptables -I OUTPUT -t raw -p udp -j CT --notrack

step "Saving iptables rules"
iptables-save > /etc/iptables.save
echo_success

step "Setting load on reboot" 
cat << __EOF >> /etc/rc.local
# Add in load of rules for LB
/sbin/iptables-restore < /etc/iptables.save
__EOF
try grep iptables-restore /etc/rc.local

echo
echo "Process Complete"

