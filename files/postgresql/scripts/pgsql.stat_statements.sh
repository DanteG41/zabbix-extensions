#!/bin/sh
# Author: Mamedaliev K.O.
# сбор информации о выполнении запросов
# первый параметр - статистика, второй - имя базы (опциональный)

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 2 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$2"
fi

PARAM="$1"

. "$(dirname -- "$0")/pgsql.pgver.inc.sh"
pgsql_cached_pgver

case "$PG_VER" in
9.*|10|11|12 )
	TIME_COL=total_time
;;
* )
	# PG 13+: total_time renamed to total_exec_time
	TIME_COL=total_exec_time
;;
esac

case "$PARAM" in
'avg_query' )
	query="SELECT (sum($TIME_COL) / sum(calls))::numeric(6,3) AS avg_query FROM pg_stat_statements;"
;;
'calls' )
	query="SELECT sum(calls) AS total_calls FROM pg_stat_statements"
;;
* ) echo "ZBX_NOTSUPPORTED"; exit 1;;
esac

psql -qAtX -F: -c "$query" -h localhost -U "$username" "$dbname"
