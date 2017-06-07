#!/usr/bin/env bash
# Author: 	Mamedaliev K.O.
# Description:	Londiste node info
# $1 - param

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
'node_without_queue' )
        q="SELECT count(*) FROM pgq_node.node_info  WHERE node_type ='root' AND queue_name NOT IN (SELECT queue_name FROM pgq.queue)"
;;
* ) echo ZBX_NOTSUPPORTED; exit 1;;
esac

r=$(psql -h localhost -p 5432 -tA -U "$username" "$dbname" -c "$q")
exit_code=$?
if [ $exit_code != 0 ]; then
        printf "Error : [%d] when executing query '$q'\n" $exit_code
        exit $exit_code
else
        [[ -z "$r" ]] && echo 0 || echo $r|head -n 1
fi
