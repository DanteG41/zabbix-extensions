#!/bin/bash
#
#  Author: Vadim Cherepanov
#  Description: Comparation between quantity of indices loaded into MySQL and count of its in sphinx.conf.
#

RESULT=0
PIDS=$(pgrep -P1 searchd); [[ -z "$PIDS" ]] && failed "ZBX_NOTSUPPORTED" 1

failed () {
  echo $1
  exit $2
}

for instance in $PIDS;
  do
    cmd=$(ps -o cmd= -p $instance)
    config=$(awk '{print $2}' <<< `getopt -u -q --long config: ${cmd}`)

    MYSQL_HOST=$(awk -F[:=] '!/^(\s|\t)*#/&&/^(\s|\t)*listen.*mysql41/ {gsub(" ","", $0); result=$2; matchs=1; exit} END {if (matchs!=1) exit 1;else print result}' $config) \
    || failed "ZBX_NOTSUPPORTED" $?
    MYSQL_PORT=$(awk -F[:=] '!/^(\s|\t)*#/&&/^(\s|\t)*listen.*mysql41/ {gsub(" ","", $0); result=$3; matchs=1; exit} END {if (matchs!=1) exit 1;else print result}' $config) \
    || failed "ZBX_NOTSUPPORTED" $?
    COUNT_CONF=$(awk '/^(\s|\t)*index(\s|\t)+/ {count++}; END {print count+0; matchs=1}; END {if (matchs!=1) exit 1}' $config) \
    || failed "ZBX_NOTSUPPORTED" $?
    COUNT_MYSQL=$(mysql -N -h $MYSQL_HOST -P $MYSQL_PORT <<< "SHOW TABLES" | awk 'END {print NR}'; ec=${PIPESTATUS[1]}; if [ $ec != 0 ]; then exit $ec; fi) \
    || failed "ZBX_NOTSUPPORTED" $?
    RESULT=$[ $COUNT_CONF - $COUNT_MYSQL ]

    if [[ ${RESULT} -gt 0 ]]; then
      echo ${RESULT}
      exit 0
    fi
done

echo ${RESULT}
