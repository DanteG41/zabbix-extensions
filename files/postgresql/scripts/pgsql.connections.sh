#!/bin/sh
# Author: Alexey Lesovsky
# сбор информации о текущих подключениях к БД
# первым параметром указывается статус процесса, вторым - база (опционально)

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

read_cached_pgver() {
  PG_VER=$(<${1})
}
update_cached_pgver() {
  psql -qAtX -F: -c "SHOW server_version" -h localhost -U "$username" "$dbname"|grep -oP "^(9\.[0-9]+|[0-9]+)" > ${1}
}

# Кэширование версии PG
CACHE_TIME=$(date -d 'now - 1hour' +%s)
TMP_FILE=/tmp/zabbix_${dbname}_pgver.tmp
if [ -f ${TMP_FILE} ]; then
  TMP_TIME=$(stat -c%Y ${TMP_FILE})
  if (( ${TMP_TIME} <= ${CACHE_TIME} )); then
    update_cached_pgver ${TMP_FILE}
  fi
  read_cached_pgver ${TMP_FILE}
else
  update_cached_pgver ${TMP_FILE}
  read_cached_pgver ${TMP_FILE}
fi

case "$PG_VER" in
9.[4-6] )
  case "$PARAM" in
  'idle_in_transaction' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state IN ('idle in transaction', 'idle in transaction (aborted)');"
  ;;
  'idle' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'idle';"
  ;;
  'total' )
          query="SELECT COUNT(*) FROM pg_stat_activity;"
  ;;
  'active' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"
  ;;
  'waiting'|'waiting_event' )
	  if [ $PG_VER == '9.6' ];then
		  query="SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock';"
	  else
		  query="SELECT COUNT(*) FROM pg_stat_activity WHERE waiting <> 'f';"
	  fi
  ;;
  'total_pct' )
          query="select count(*)*100/(select (setting::int) from pg_settings where name = 'max_connections') from pg_stat_activity;"
  ;;
  * ) echo "ZBX_NOTSUPPORTED"; exit 1;;
  esac
;;
* )
  case "$PARAM" in
  'idle_in_transaction' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state IN ('idle in transaction', 'idle in transaction (aborted)') AND backend_type = 'client backend';"
  ;;
  'idle' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'idle' AND backend_type = 'client backend';"
  ;;
  'total' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state IS NOT NULL AND backend_type = 'client backend';"
  ;;
  'active' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active' AND backend_type = 'client backend';"
  ;;
  'waiting'|'waiting_event' )
          query="SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND backend_type = 'client backend';"
  ;;
  'total_pct' )
          query="select count(*)*100/(select (setting::int) from pg_settings where name = 'max_connections') from pg_stat_activity WHERE state IS NOT NULL AND backend_type = 'client backend';"
  ;;
  * ) echo "ZBX_NOTSUPPORTED"; exit 1;;
  esac
esac

psql -qAtX -F: -c "$query" -h localhost -U "$username" "$dbname"
