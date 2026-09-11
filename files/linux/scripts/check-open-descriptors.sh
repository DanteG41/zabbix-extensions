#!/bin/bash
# Author:	Lesovsky A.V.
# Description:  Search open handlers deleted files and output file size associated with the handler.

LSOF=$(which lsof)
ZBX_CONFIG="/etc/zabbix/zabbix_agentd.conf"

GLOBAL_BIG=0
for mount in $(cat /proc/mounts |grep -wE 'ext[2-4]+|xfs' |awk '{print $2}');
  do
    LOCAL_BIG=$($LSOF $mount |grep -i del |awk '{print $7}' |sort -n |tail -n1)
    [[ ! -z "$LOCAL_BIG" && $LOCAL_BIG -ge $GLOBAL_BIG ]] && GLOBAL_BIG=$LOCAL_BIG
  done

zabbix_sender -c $ZBX_CONFIG -s $(hostname) -k system.deleted_filehandler_maxsize -o "$GLOBAL_BIG" &> /dev/null
