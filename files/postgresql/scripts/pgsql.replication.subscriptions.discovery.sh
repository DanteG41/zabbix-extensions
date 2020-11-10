#!/usr/bin/env bash
# Author:       Mamedaliev K.O. <danteg41@gmail.com>
# Description: Replication subscriptions auto-discovery.
# First arg (opt) - database name

username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)

if [ "$#" -lt 1 ]; 
  then 
    if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
    dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3);
  else
    dbname="$1"
fi

query="SELECT subname FROM pg_stat_subscription"

subscriptions=$(psql -h localhost -p 5432 -qtAX -F: -U "$username" "$dbname" -c "SET search_path = 'pg_catalog';$query")

exit_code=$?
if [ $exit_code != 0 ]; then
  printf "Error : [%d] when executing query '$q'\n" $exit_code
  exit $exit_code
fi

first=1
printf "{\n";
printf "\t\"data\":[\n\n";

for SUBSCRIPTION in ${subscriptions}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#SUBSCRIPTION}\":\"${SUBSCRIPTION}\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
