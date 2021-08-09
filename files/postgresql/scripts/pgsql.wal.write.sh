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
  query="select pg_xlogfile_name(pg_current_xlog_location())"
;;
* )
  query="select pg_walfile_name(pg_current_wal_flush_lsn())"
esac

POS=$(psql -qAtX -c "$query" -h localhost -U "$username" "$dbname" | cut -b 9-16,23-24)

echo $((0x$POS))
