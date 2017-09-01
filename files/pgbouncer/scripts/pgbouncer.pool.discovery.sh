#!/usr/bin/env bash
# Author: 	Lesovsky A.V.
# Description:	Pgbouncer pools auto-discovery

if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi
config='/etc/pgbouncer.ini'
hostname=$(grep -w ^listen_addr $config |cut -d" " -f3 |cut -d, -f1)
port=${1:-6432}
dbname="pgbouncer"
username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)
first=1

if [ '*' = "$hostname" ]; then hostname="127.0.0.1"; fi

poollist=$(psql -h $hostname -p $port -U $username -tAF: --dbname=$dbname -c "show pools" |cut -d: -f1 |grep -v ^pgbouncer|uniq)

printf "{\n";
printf "\t\"data\":[\n\n";

for line in ${poollist}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#POOLNAME}\":\"$line\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
