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

SLOT="$1"

case "$PARAM" in
'state' )
	q="SELECT CASE active WHEN true THEN 1 ELSE 0 END as state FROM pg_replication_slots WHERE slot_name = '$SLOT';"
;;
'byte_lag' )
	q="SELECT pg_wal_lsn_diff(pg_current_wal_lsn(),confirmed_flush_lsn) FROM pg_replication_slots WHERE slot_name = '$SLOT'"
;;
* ) exit 1;;
esac

echo $q |psql -h localhost -p 5432 -tA -U "$username" "$dbname"
