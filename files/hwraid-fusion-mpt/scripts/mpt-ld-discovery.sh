#!/usr/bin/env bash
# Author: Mamedaliev K.O. <danteg41@protonmail.com>
# Logical drives auto-discovery via mpt-status.

mpt_cmd="/usr/sbin/mpt-status"
LD_LIST=$(grep -oP "(?<=Found\ SCSI\ id=)\d+" <(sudo ${mpt_cmd} --autoload -p))
first=1

printf "{\n";
printf "\t\"data\":[\n\n";

for ld in ${LD_LIST}
do
    [ $first != 1 ] && printf ",\n";
    first=0;
    printf "\t{\n";
    printf "\t\t\"{#LD}\":\"$ld\"\n";
    printf "\t}";
done

printf "\n\t]\n";
printf "}\n";
