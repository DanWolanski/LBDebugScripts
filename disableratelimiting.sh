# Script to setup network and hostname

cat <<'__EOF' >> /etc/rsyslog.conf
$SystemLogRateLimitInterval 0
$SystemLogRateLimitBurst 0
__EOF

systemctl restart systemd-journald.service
