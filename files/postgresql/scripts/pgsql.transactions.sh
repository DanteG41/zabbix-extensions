#!/bin/sh
# Author: Alexey Lesovsky
# сбор информации о транзакциях
# первый параметр - статус транзакции, второй - имя базы (опциональный)

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

case "$PARAM" in
'idle' )
        query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE state like 'idle in transaction%';"
;;
'active' )
	query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE state NOT like 'idle%'"
;;
'active_without_autovacuum' )
	query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE state NOT like 'idle%' AND query NOT LIKE 'autovacuum:%'"
;;
'waiting' )
	query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE waiting = 't'"
;;
'waiting_without_autovacuum' )
        query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE waiting = 't' AND query NOT LIKE 'autovacuum:%'"
;;
'waiting_event' )
        query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension') AND state NOT like 'idle%'"
;;
'waiting_event_without_autovacuum' )
        query="SELECT COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), query_start))), 0) as d FROM pg_stat_activity WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension') AND query NOT LIKE 'autovacuum:%' AND state NOT like 'idle%'"
;;
'pending_xa_count' )
	query="SELECT count(*) FROM pg_prepared_xacts where COALESCE(EXTRACT (EPOCH FROM age(NOW(), prepared)), 0) > 1000;"
;;
'pending_xa_max_time' )
	query="SELECT COALESCE(EXTRACT (EPOCH FROM max(age(NOW(), prepared))), 0) as d FROM pg_prepared_xacts;"
;;
'transactions_counter' )
	query="SELECT sum(xact_commit+xact_rollback) FROM pg_stat_database;"
;;
'*' ) echo "ZBX_NOTSUPPORTED"; exit 1;;
esac

psql -qAtX -F: -c "$query" -h localhost -U "$username" "$dbname"
