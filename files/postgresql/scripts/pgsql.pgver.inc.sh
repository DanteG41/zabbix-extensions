# Shared PostgreSQL version cache for pgsql.*.sh
# Requires: username, dbname
# Sets: PG_VER (e.g. 9.6, 11, 17)

pgsql_read_cached_pgver() {
  PG_VER=$(cat "${1}")
}

pgsql_update_cached_pgver() {
  psql -qAtX -F: -c "SHOW server_version" -h localhost -U "$username" "$dbname" | grep -oP "^(9\.[0-9]+|[0-9]+)" > "${1}"
}

pgsql_cached_pgver() {
  CACHE_TIME=$(date -d 'now - 1hour' +%s)
  TMP_FILE=/tmp/zabbix_${dbname}_pgver.tmp
  if [ -f "${TMP_FILE}" ]; then
    TMP_TIME=$(stat -c%Y "${TMP_FILE}")
    if [ "${TMP_TIME}" -le "${CACHE_TIME}" ]; then
      pgsql_update_cached_pgver "${TMP_FILE}"
    fi
    pgsql_read_cached_pgver "${TMP_FILE}"
  else
    pgsql_update_cached_pgver "${TMP_FILE}"
    pgsql_read_cached_pgver "${TMP_FILE}"
  fi
}
