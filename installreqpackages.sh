#!/bin/bash
# This script will install the packages that are needed for the mrb

. /etc/init.d/functions
starttime=`date +"%Y-%m-%d_%H-%M-%S"`
LOG="packageinstall.log"
if [ $# -eq 1 ]; then
	OUTFILE=$1
fi
# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
step() {
    echo -n -e "$@"
    echo -e "\n\nSTEP -  $@"&>> $LOG
    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}
next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo

    return $STEP_OK
}
setpass() {
    echo -n "$@"
    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

echo "Basic Packages"
PACKAGELIST="vim wget unzip net-snmp net-snmp-libs net-snmp-utils net-tools expect nmap"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	yum -y install $PACKAGE &>> $LOG
	next;
done

echo "MRB w/ Proxy enabled packages"

PACKAGELIST="epel-release glib2-devel glibc-devel zlib-devel openssl-devel pcre-devel libcurl-devel xmlrpc-c xmlrpc-c-devel iptables-devel gcc kernel-devel hiredis hiredis-devel"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	yum -y install $PACKAGE &>> $LOG
	next;
done

step "Updating the kernel via yum"
yum -y update kernel &>> $LOG
next
echo "Note- kernel update requires a system restart"
echo
echo "Process complete, see $LOG for details"
