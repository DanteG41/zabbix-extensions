#!/bin/sh
# Author: Mamedaliev Kirill
# Denormaliztion fileds statistics

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

#если имя базы не получено от сервера, то имя берется из первой строки ~zabbix/.pgpass
if [ "$#" -lt 3 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$3"
fi
PARAM="$1"

case "$PARAM" in
'state' )
        query_substr="SELECT state FROM denormalization.fields where title = '$2' LIMIT 1"
;;
* ) echo "ZBX_NOTSUPPORTED"; exit 1;;
esac

if [ -z "$3" ];
  then
    query="$query_substr"
  else
    query="$query_substr WHERE datname = '$dbname'"
fi

r=$(psql -qAtX -F: -c "$query" -h localhost -U "$username" "$dbname")
exit_code=$?
if [ $exit_code != 0 ]; then
        printf "Error : [%d] when executing query '$q'\n" $exit_code
        exit $exit_code
else
        [[ -z "$r" ]] && echo 0 || echo $r|head -n 1
fi
