#!/usr/bin/env bash
# Author:	Lesovsky A.V.
# Description:	Pgbouncer pools stats
# $1 - param_name, $2 - pool_name

if [ ! -f ~zabbix/.pgpass ]; then echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; fi

PSQL=$(which psql)
config='/etc/pgbouncer.ini'
hostname=$(grep -w ^listen_addr $config |cut -d" " -f3 |cut -d, -f1)
port=6432
dbname="pgbouncer"
username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)
PARAM="$1"

if [ '*' = "$hostname" ]; then hostname="127.0.0.1"; fi

conn_param="-qAtX -F: -h $hostname -p $port -U $username $dbname"

case "$PARAM" in
'avg_req' )
        $PSQL $conn_param -c "show stats" |grep -w $2 |cut -d: -f6
;;
'avg_recv' )
        $PSQL $conn_param -c "show stats" |grep -w $2 |cut -d: -f7
;;
'avg_sent' )
        $PSQL $conn_param -c "show stats" |grep -w $2 |cut -d: -f8
;;
'avg_query' )
        $PSQL $conn_param -c "show stats" |grep -w $2 |cut -d: -f9
;;
'cl_active' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $3} END {print sum}'
;;
'cl_waiting' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $4} END {print sum}'
;;
'sv_active' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $5} END {print sum}'
;;
'sv_idle' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $6} END {print sum}'
;;
'sv_used' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $7} END {print sum}'
;;
'sv_tested' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $8} END {print sum}'
;;
'sv_login' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $9} END {print sum}'
;;
'maxwait' )
        $PSQL $conn_param -c "show pools" | awk -v "POOL_NAME=$2" -F ":" '$1 ~ POOL_NAME {sum += $10} END {print sum}'
;;
'free_clients' )
        $PSQL $conn_param -c "show lists" |grep -w free_clients |cut -d: -f2
;;
'used_clients' )
        $PSQL $conn_param -c "show lists" |grep -w used_clients |cut -d: -f2
;;
'login_clients' )
        $PSQL $conn_param -c "show lists" |grep -w login_clients |cut -d: -f2
;;
'free_servers' )
        $PSQL $conn_param -c "show lists" |grep -w free_servers |cut -d: -f2
;;
'used_servers' )
        $PSQL $conn_param -c "show lists" |grep -w used_servers |cut -d: -f2
;;
'total_avg_req' )
        $PSQL $conn_param -c "show stats" |cut -d: -f6 |awk '{ s += $1 } END { print s }'
;;
'total_avg_recv' )
        $PSQL $conn_param -c "show stats" |cut -d: -f7 |awk '{ s += $1 } END { print s }'
;;
'total_avg_sent' )
        $PSQL $conn_param -c "show stats" |cut -d: -f8 |awk '{ s += $1 } END { print s }'
;;
'total_avg_query' )
        $PSQL $conn_param -c "show stats" |cut -d: -f6,9 |awk -F: '{ a += $1 * $2} { b += $1} END { print a / b }'
;;
* ) echo "ZBX_NOTSUPPORTED"; exit 1;;
esac
