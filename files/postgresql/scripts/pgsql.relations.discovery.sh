#!/usr/bin/env bash
# Author:       Mamedaliev K.O. <danteg41@gmail.com>
# Description: Relations auto-discovery from table monitoring.monitored_relations (see monitoring.sql). 
# Example of adding a table to monitoring. From user with role monitoring_op: 
# "INSERT INTO monitoring.monitored_relations VALUES ('product_images');" 
# OR parent table with inheritance 
# "INSERT INTO monitoring.monitored_relations (relname, inheritance) VALUES ('orders.archived_orders',true);"
# First arg - relation type (tables,parent_tables,indices)
# Second arg (opt)- database name

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

if [ "$#" -lt 2 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$2"
fi

TYPE="$1"

case "$TYPE" in
'tables' )
  query="SELECT OID::regclass::text FROM pg_class WHERE relkind ='r' AND OID IN (SELECT relid FROM monitoring.monitored_relations WHERE monitored=true AND inheritance=false)"
;;
'parent_tables' )
  query="SELECT OID::regclass::text FROM pg_class WHERE relkind ='r' AND OID IN (SELECT relid FROM monitoring.monitored_relations WHERE monitored=true AND inheritance=true)"
;;
'indices' )
  query="SELECT OID::regclass::text FROM pg_class WHERE relkind ='i' AND OID IN (SELECT relid FROM monitoring.monitored_relations WHERE monitored=true)"
;;
* ) echo "ZBX_NOTSUPPORTED"; exit 1;;
esac

relations=$(psql -h localhost -p 5432 -qtAX -F: -U "$username" "$dbname" -c "SET search_path = 'pg_catalog';$query")

exit_code=$?
if [ $exit_code != 0 ]; then
  printf "Error : [%d] when executing query '$q'\n" $exit_code
  exit $exit_code
fi

first=1
printf "{\n";
printf "\t\"data\":[\n\n";

for RELATION in ${relations}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#RELATION}\":\"${RELATION}\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
