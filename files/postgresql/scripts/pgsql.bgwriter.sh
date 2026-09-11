#!/usr/bin/env bash
# Description: bgwriter / checkpointer statistics.
# Keys keep historic pg_stat_bgwriter column names; PG 17 maps them to pg_stat_checkpointer.

[[ -f ~zabbix/.pgpass ]] || { echo "ERROR: ~zabbix/.pgpass not found" ; exit 1; }
username=$(head -n 1 ~zabbix/.pgpass |cut -d: -f4)
dbname=$(head -n 1 ~zabbix/.pgpass |cut -d: -f3)
PARAM="$1"

. "$(dirname -- "$0")/pgsql.pgver.inc.sh"
pgsql_cached_pgver

case "$PG_VER" in
9.*|1[0-6] )
	query="SELECT $PARAM FROM pg_stat_bgwriter"
;;
* )
	case "$PARAM" in
	'buffers_checkpoint' )
		query="SELECT buffers_written FROM pg_stat_checkpointer"
	;;
	'checkpoints_req' )
		query="SELECT num_requested FROM pg_stat_checkpointer"
	;;
	'checkpoints_timed' )
		query="SELECT num_timed FROM pg_stat_checkpointer"
	;;
	'checkpoint_sync_time' )
		query="SELECT sync_time FROM pg_stat_checkpointer"
	;;
	'checkpoint_write_time' )
		query="SELECT write_time FROM pg_stat_checkpointer"
	;;
	* )
		query="SELECT $PARAM FROM pg_stat_bgwriter"
	;;
	esac
;;
esac

psql -qAtX -c "$query" -h localhost -U "$username" "$dbname" 2>/dev/null || { echo ZBX_NOTSUPPORTED; exit 1; }
