#!/usr/bin/env bash
# суть проверки выяснить момент когда использование памяти подходит к критической границе 
# когда кэши невозможно занять, память заполнена и система вот-вот начнет реально свопиться.

# /proc/meminfo fields have stable meaning across kernel/procps versions, unlike
# free(1)'s "used" column, whose formula changed in procps-ng (it started netting
# out buff/cache itself), which made subtracting buffers/cache from it again wrong.
TOTALRAM=$(grep ^MemTotal: /proc/meminfo |awk '{print $2}')
FREERAM=$(grep ^MemFree: /proc/meminfo |awk '{print $2}')
BUFFERS=$(grep ^Buffers: /proc/meminfo |awk '{print $2}')
PAGECACHE=$(grep ^Cached: /proc/meminfo |awk '{print $2}')
SWAPTOTAL=$(grep ^SwapTotal: /proc/meminfo |awk '{print $2}')
SWAPFREE=$(grep ^SwapFree: /proc/meminfo |awk '{print $2}')
USEDSWAP=$((SWAPTOTAL - SWAPFREE))
USED=$((TOTALRAM - FREERAM - BUFFERS - PAGECACHE + USEDSWAP))

awk "BEGIN {print $USED/$TOTALRAM*100}" |cut -d. -f1
