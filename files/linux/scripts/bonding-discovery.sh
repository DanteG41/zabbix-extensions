#!/bin/bash
#Zabbix vfs.dev.discovery implementation

DEVS=$(</sys/class/net/bonding_masters)
first=1

printf "{\n";
printf "\t\"data\":[\n\n";

for DEV in ${DEVS}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#BONDNAME}\":\"${DEV}\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
