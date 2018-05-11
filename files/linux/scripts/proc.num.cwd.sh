#!/bin/bash
# Author:       Mamedaliev K.O.
# Description:  Show the count of processes where CWD match/not match (show no matches by default)
# $1 - process name, $2 - path, $3 - show matches (optional)
 
zbx_ns () {
  echo "ZBX_NOTSUPPORTED"; exit 1
}

proc_num_match=0
proc_num_unmatch=0
CMDLINE=$1
DIR=$(readlink -e $2) || zbx_ns
match=${3:-false}

[ "$#" -lt 2 ] && zbx_ns

while read pid; do
  if [[ ${DIR} == $(sudo lsof  -a -p ${pid} -d cwd -Fn|sed -n 's/^n//p') ]]
    then ((proc_num_match++))
    else ((proc_num_unmatch++))
  fi
done < <(pgrep -f ${CMDLINE})

${match} && echo ${proc_num_match} || echo ${proc_num_unmatch}
