#!/bin/sh
# Author: Mamedaliev Kirill
# сбор статистики по notification_queue
# первым параметр - параметр статистики
# второй парамтер (опц.) - имя базы

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 2 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$2"
fi
# определяем какую харакетристику будем искать
PARAM="$1"

case "$PARAM" in
'usage' )
	q="SELECT pg_notification_queue_usage()"
;;
* ) exit 1;;
esac

RESULT=$(psql -qAtX -F: -c "$q" -h localhost -U "$username" "$dbname")
exit_code=$?

if [ $exit_code != 0 ]; then
        printf "Error : [%d] when executing query '${q}'\n" $exit_code
        exit $exit_code
else
  if [ -z "$RESULT" ]; then exit 1; else echo $RESULT; fi
fi
