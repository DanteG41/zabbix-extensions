#!/bin/sh
# Author: Kirill Mamedaliev
# сбор информации о долгих транзакциях
# первый параметр - время выполнения в минутах, второй - режим (строка или время выполнения) [str|time] ,третий - имя базы (опциональный)

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 3 ];
  then
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$3"
fi

PARAM="$1"
MODE="$2"

case "$MODE" in
'str_execute' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
order by xact_start
limit 1;"
;;
'str_execute_without_autovacuum' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
AND query NOT LIKE 'autovacuum:%'
order by xact_start
limit 1;"
;;
'time_execute' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes';"
;;
'time_execute_without_autovacuum' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
AND query NOT LIKE 'autovacuum:%';"
;;
'str_wait' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
from pg_stat_activity
WHERE waiting = 't'
order by xact_start
limit 1;"
;;
'str_wait_without_autovacuum' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
from pg_stat_activity
WHERE waiting = 't'
AND query NOT LIKE 'autovacuum:%'
order by xact_start
limit 1;"
;;
'time_wait' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
WHERE waiting = 't';"
;;
'time_wait_without_autovacuum' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
WHERE waiting = 't'
AND query NOT LIKE 'autovacuum:%';"
;;
'str_wait_event' )
query="
select
 pid, 
 usename, 
 application_name,
 pg_blocking_pids(pid) as blocked_by,
 wait_event_type,
 wait_event,
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
FROM pg_stat_activity
WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension') AND state NOT like 'idle%'
ORDER BY xact_start
LIMIT 1;"
;;
'str_wait_event_without_autovacuum' )
query="
select
 pid, 
 usename, 
 application_name,
 pg_blocking_pids(pid) as blocked_by,
 wait_event_type,
 wait_event,
 NOW() - xact_start as exectime,
 substr (query, 1, 100) as query
FROM pg_stat_activity
WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension') AND state NOT like 'idle%' AND query NOT LIKE 'autovacuum:%'
ORDER BY xact_start
LIMIT 1;"
;;
'time_wait_event' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension') AND state NOT like 'idle%';"
;;
'time_wait_event_without_autovacuum' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
WHERE wait_event_type IN ('Lock', 'LWLock', 'Extension')
AND query NOT LIKE 'autovacuum:%' AND state NOT like 'idle%';"
;;
'*' ) echo "ZBX_NOTSUPPORTED";exit 1;;
esac
resp=$(psql -qAtX -F"|" -c "$query" -h localhost -U "$username" "$dbname")
if [ ! -z "$resp" ];then echo $resp ; exit 0;
        else
         echo OK;
fi
