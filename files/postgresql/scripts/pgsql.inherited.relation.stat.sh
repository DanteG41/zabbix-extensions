#!/usr/bin/env bash
# Author: 	Mamedaliev.K.O.
# Description:	Collecting statistics of inherited tables by the name of the parent table.
# $1 - table name, $2 - statistic param, $3 - db name

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 3 ];
  then
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$3"
fi

if [ "$#" -lt 2 ]; then echo "ZBX_NOTSUPPORTED"; exit 1; fi

# определяем какую харакетристику будем искать
PARAM="$2"

case "$PARAM" in
'heapread' )
	q="SELECT sum(heap_blks_read) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'heaphits' )
	q="SELECT sum(heap_blks_hit) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'idxread' )
	q="SELECT sum(idx_blks_read) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'idxhits' )
	q="SELECT sum(idx_blks_hit) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'toastread' )
	q="SELECT sum(toast_blks_read) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'toasthits' )
	q="SELECT sum(toast_blks_hit) FROM pg_statio_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'seqscan' )
	q="SELECT sum(seq_scan) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'seqread' )
	q="SELECT sum(seq_tup_read) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'idxscan' )
	q="SELECT sum(idx_scan) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'idxfetch' )
	q="SELECT sum(idx_tup_fetch) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'inserted' )
	q="SELECT sum(n_tup_ins) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'updated' )
	q="SELECT sum(n_tup_upd) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'deleted' )
	q="SELECT sum(n_tup_del) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'hotupdated' )
	q="SELECT sum(n_tup_hot_upd) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'live' )
	q="SELECT sum(n_live_tup) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
'dead' )
	q="SELECT sum(n_dead_tup) FROM pg_stat_user_tables WHERE relid IN ( SELECT inhrelid FROM pg_inherits WHERE inhparent = '$1'::regclass::oid)"
;;
* ) exit 1;;
esac

r=$(psql -h localhost -p 5432 -qtAX -F: -U "$username" "$dbname" -c "$q")
exit_code=$?
if [ $exit_code != 0 ]; then
        printf "Error : [%d] when executing query '$q'\n" $exit_code
        exit $exit_code
else
        [[ -z "$r" ]] && echo 0 || echo $r|head -n 1
fi
