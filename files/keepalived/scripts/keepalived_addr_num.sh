#/usr/bin/env bash
#
# Determines if the IP address from keepalived.conf are available on this server
# and return number of this IP addresses (usualy 0 or all)
# Script works correct for one VRRP instance.
# Based on: https://github.com/lesovsky/zabbix-extensions
# ver 2018-09-28 by jacek

PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"

ADDRESSES=$(sed -n -e '/virtual_ipaddress {/,/}/p' $KEEPALIVED_CONF |grep -v ^# |awk '{print $1}' |grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}*')
#[[ -f $(which ip 2>/dev/null) ]] || { echo "ZBX_NOTSUPPORTED, ip utility from iproute2 not found."; exit 1; }

for addr in $ADDRESSES; do
	ip addr show |grep -o "$addr";
done |wc -l
