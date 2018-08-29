#!/usr/bin/env bash
# Author: 	Mamedaliev.K.O.
# Description:	size of indices inherited tables by name of parent table.

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из ~zabbix/.pgpass
if [ "$#" -lt 2 ];
  then
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$2"
fi

if [ -z "$*" ]; then echo "ZBX_NOTSUPPORTED"; exit 1; fi

q="SELECT sum(pg_total_relation_size(inhrelid::regclass) - pg_relation_size(inhrelid::regclass)) FROM pg_inherits WHERE inhparent = '$1'::regclass::oid;"

r=$(psql -h localhost -p 5432 -qtAX -F: -U "$username" "$dbname" -c "$q")
exit_code=$?
if [ $exit_code != 0 ]; then
        printf "Error : [%d] when executing query '$q'\n" $exit_code
        exit $exit_code
else
        [[ -z "$r" ]] && echo 0 || echo $r|head -n 1
fi
