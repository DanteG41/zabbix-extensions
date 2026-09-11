#!/usr/bin/env bash
# Author:       Kirill Mamedaliev <danteg41@gmail.com>
# Description:  Elasticsearch instance memory

PARAM="$1"
MODE="$2"

case "$MODE" in
'rsz' )
ps h -o rsz $(cat $PARAM/*.pid|xargs)|paste -sd+ |bc
;;
'rbig' )
ps h -o rsz $(cat $PARAM/*.pid|xargs)|sort -rnk1 |head -n 1
;;
'rsmall' )
ps h -o rsz,cmd $(cat $PARAM/*.pid|xargs)|awk '{print $1}' |sort -rnk1 |tail -n 1
;;
'ravg' )
echo \($(ps h -o rsz $(cat $PARAM/*.pid|xargs)|paste -sd+)\)\/$(ps h -o vsz $(cat $PARAM/*.pid|xargs)|wc -l) |bc
;;
'vsz' )
ps h -o vsz $(cat $PARAM/*.pid|xargs)|paste -sd+ |bc
;;
'vbig' )
ps h -o vsz $(cat $PARAM/*.pid|xargs)|sort -rnk1 |head -n 1
;;
'vsmall' )
ps h -o vsz,cmd $(cat $PARAM/*.pid|xargs)|awk '{print $1}' |sort -rnk1 |tail -n 1
;;
'vavg' )
echo \($(ps h -o vsz $(cat $PARAM/*.pid|xargs)|paste -sd+)\)\/$(ps h -o vsz $(cat $PARAM/*.pid|xargs)|wc -l) |bc
;;
'*' ) echo "ZBX_NOTSUPPORTED";exit 1;;
esac
