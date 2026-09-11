#!/usr/bin/env bash
# Author:	Lesovsky A.V.
# Description:	yum updates info

YUM_RESULT=/tmp/yum-security.out
ZBX_DATA=/tmp/zabbix-sender-yum-data.in
ZBX_CONFIG="/etc/zabbix/zabbix_agentd.conf"

CHECK_UPDATE_OUT=$(yum check-update -q --errorlevel=0)
rc=$?
# 0 = no updates, 100 = updates available, anything else = yum itself failed
if [ $rc -ne 0 ] && [ $rc -ne 100 ]; then
  echo "yum check-update failed with exit code $rc" >&2
  exit 1
fi
TOTAL_UPDATES=0
[ -n "$CHECK_UPDATE_OUT" ] && TOTAL_UPDATES=$(printf '%s\n' "$CHECK_UPDATE_OUT" |wc -l)

yum list-security -q --errorlevel=0 |awk '{print $2}' |sort |uniq -c > /tmp/yum-bugs
rc=${PIPESTATUS[0]}
if [ $rc -ne 0 ]; then
  echo "yum list-security failed with exit code $rc" >&2
  exit 1
fi

low=$(grep 'Low/Sec.' /tmp/yum-bugs |awk '{print $1}')
moderate=$(grep 'Moderate/Sec.' /tmp/yum-bugs |awk '{print $1}')
important=$(grep 'Important/Sec.' /tmp/yum-bugs |awk '{print $1}')
critical=$(grep 'Critical/Sec.' /tmp/yum-bugs |awk '{print $1}')
enhancement=$(grep 'enhancement' /tmp/yum-bugs |awk '{print $1}')
bugfix=$(grep 'bugfix' /tmp/yum-bugs |awk '{print $1}')

[[ ! $low ]] && low=0
[[ ! $moderate ]] && moderate=0
[[ ! $important ]] && important=0
[[ ! $critical ]] && critical=0
[[ ! $enhancement ]] && enhancement=0
[[ ! $bugfix ]] && bugfix=0

echo -n > $ZBX_DATA
echo "$(hostname) rh.updates.enh $enhancement" >> $ZBX_DATA
echo "$(hostname) rh.updates.bugfix $bugfix" >> $ZBX_DATA
echo "$(hostname) rh.updates.low $low" >> $ZBX_DATA
echo "$(hostname) rh.updates.mod $moderate" >> $ZBX_DATA
echo "$(hostname) rh.updates.imp $important" >> $ZBX_DATA
echo "$(hostname) rh.updates.crit $critical" >> $ZBX_DATA
echo "$(hostname) rh.updates.total $TOTAL_UPDATES" >> $ZBX_DATA

zabbix_sender -c $ZBX_CONFIG -i $ZBX_DATA &> /dev/null
