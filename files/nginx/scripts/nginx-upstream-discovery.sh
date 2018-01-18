#!/usr/bin/env bash
# Author:	Mamedaliev K.O. <danteg41@gmail.com>
# Description:	Nginx upstream auto-discovery

NGINX_CONFDIR="/etc/nginx"

upstreams=$(grep -ilr "upstream.*{" ${NGINX_CONFDIR} |\
  while read file;do \
    awk 'SSL=""; PORT=""; /upstream.*{/,/}/ {
      if ($1=="server") {
        if ($2 ~/unix:\//) next
        if ($2 !~ /:[0-9]+/ ) {
          if ($2~/http:\/\//) {PORT=":80"}
          if ($2~/https:\/\//) {PORT=":443"}
        }
        if ($2~/https:\/\//) {SSL="s"}
        gsub(/(;|https?:\/\/)/,"",$2)
        print "http" SSL":"$2 PORT|"sort|uniq"
      }
    }' ${file};\
  done)
first=1

printf "{\n";
printf "\t\"data\":[\n\n";

while IFS=":" read UPSTREAM_PROTO UPSTREAM_NAME UPSTREAM_PORT
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#UPSTREAM_NAME}\":\"${UPSTREAM_NAME}\",\n";
    printf "\t\t\"{#UPSTREAM_PROTO}\":\"${UPSTREAM_PROTO}\",\n";
    printf "\t\t\"{#UPSTREAM_PORT}\":\"${UPSTREAM_PORT}\"\n";
    printf "\t}";
done <<< "${upstreams}"

printf "\n\t]\n";
printf "}\n";

