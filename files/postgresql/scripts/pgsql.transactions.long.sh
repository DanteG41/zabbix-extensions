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
'str' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start, 
 substr (query, 1, 100)
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
order by NOW() - interval '$PARAM minutes' desc
limit 1;"
;;
'str_without_autovacuum' )
query="
select 
 pid, 
 usename, 
 application_name, 
 NOW() - xact_start, 
 substr (query, 1, 100)
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
AND query NOT LIKE 'autovacuum:%'
order by NOW() - interval '$PARAM minutes' desc
limit 1;"
;;
'time' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
order by NOW() - interval '$PARAM minutes' desc
limit 1;"
;;
'time_without_autovacuum' )
query="
select 
 COALESCE(EXTRACT (EPOCH FROM MAX(age(NOW(), xact_start))), 0) as d
from pg_stat_activity
where xact_start < NOW() - interval '$PARAM minutes'
AND query NOT LIKE 'autovacuum:%'
order by NOW() - interval '$PARAM minutes' desc
limit 1;"
;;
'*' ) echo "ZBX_NOTSUPPORTED";exit 1;;
esac
resp=$(psql -qAtX -F"|" -c "$query" -h localhost -U "$username" "$dbname")
if [ ! -z "$resp" ];then echo $resp ; exit 0;
        else
         echo OK;
fi
