#!/bin/sh
# Author: Alexey Lesovsky
# сбор информации об интенсивности записи WAL-журналов

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 2 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$2"
fi

. "$(dirname -- "$0")/pgsql.pgver.inc.sh"
pgsql_cached_pgver

case "$PG_VER" in
9.[4-6] )
  query="select pg_xlogfile_name(pg_current_xlog_location())"
;;
* )
  query="select pg_walfile_name(pg_current_wal_flush_lsn())"
esac

POS=$(psql -qAtX -c "$query" -h localhost -U "$username" "$dbname" | cut -b 9-16,23-24)

echo $((0x$POS))
