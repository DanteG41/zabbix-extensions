#!/usr/bin/env bash
# Author:	Lesovsky A.V.
# Description:	Swap discovery

SIZE=$(swapon -s |grep -v ^Filename |awk '{sum += $3} END {print sum}')

printf "{\n";
printf "\t\"data\":[\n\n";

if [ ! -z $SIZE ]; then
  printf "\t{\n";
  printf "\t\t\"{#SWAP_EXISTS}\":\"\"\n";
  printf "\t}\n";
fi

printf "\n\t]\n";
printf "}\n";
