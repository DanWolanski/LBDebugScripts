#!/bin/bash
. /etc/init.d/functions
starttime=`date +"%Y-%m-%d_%H-%M-%S"`
LOG='/dev/null'
EXTTYPE='tar.gz'
while getopts 'rt' flag; do
  case "${flag}" in
    r) EXTTYPE='rpm' ;;
    t) EXTTYPE='tar.gz' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done
echo "Setting EXTTYPE to $EXTTYPE"
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
step "Fetching jdk list from oracle web"
if [ "$EXTTYPE" == "rpm" ]; then
LATESTJDK=$(curl -s http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html | grep -oP 'http://download.oracle.com/otn-pub/java/jdk/8u.*?/jdk-8u.*?-linux-x64.rpm' | tail -1)
else
LATESTJDK=$(curl -s http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html | grep -oP 'http://download.oracle.com/otn-pub/java/jdk/8u.*?/jdk-8u.*?-linux-x64.tar.gz' | tail -1)
fi
next
echo "    Latest jdk detected as:" 
echo "        $LATESTJDK"
echo 
if [ "$EXTTYPE" == "rpm" ]; then
FILENAME=$(echo $LATESTJDK  | grep -oP "jdk-8u.*?-linux-x64.rpm")
else
FILENAME=$(echo $LATESTJDK  | grep -oP "jdk-8u.*?-linux-x64.tar.gz")
fi

step "Downloading $FILENAME"
curl -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" -o $FILENAME $LATESTJDK &>> $LOG
next

if [ "$EXTTYPE" == "rpm" ]; then
step "Yum installing $FILENAME"
sudo rpm -i $FILENAME
else
step "Extracting $FILENAME to /opt"
tar xvzf $FILENAME -C /opt &>> $LOG
fi
next