#!/usr/bin/env bash
# Author:       Mamedaliev K.O. <danteg41@gmail.com>
# Description:  External ip auto-discovery

ips=$(grep -oP '(?<=inet\s)(?!((127|10)\.\d+|172\.(1[6-9]|2[0-9]|3[0-1])|192\.168)(\.\d+){2})(\d+\.){3}\d+' <(ip -4 addr))
first=1

printf "{\n";
printf "\t\"data\":[\n\n";

for IP in ${ips}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#EXTERNAL_IP}\":\"${IP}\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
