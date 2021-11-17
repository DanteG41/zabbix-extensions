#!/bin/sh
# Author: Mamedaliev Kirill

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 3 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$3"
fi

PARAM="$2"

SUBSCRIPTION="$1"

case "$PARAM" in
'state' )
	q="SELECT min(CASE COALESCE(pid,0) WHEN 0 THEN 0 ELSE 1 END) as state FROM pg_stat_subscription WHERE subname = '$SUBSCRIPTION'"
;;
'byte_lag' )
	q="SELECT max(COALESCE(pg_wal_lsn_diff(received_lsn,latest_end_lsn),0)) as byte_lag FROM pg_stat_subscription WHERE subname = '$SUBSCRIPTION'"
;;
'lag' )
	q="SELECT max(COALESCE(round(extract(epoch from (last_msg_receipt_time - last_msg_send_time))),0)) as lag FROM pg_stat_subscription WHERE subname = '$SUBSCRIPTION'"
;;
* ) exit 1;;
esac

echo $q |psql -h localhost -p 5432 -tA -U "$username" "$dbname"
