#!/bin/bash
# Author:       Mamedaliev K.O.
# Description:  This script return time of execution needed to send message rsyslogd.

export LC_NUMERIC="en_US.utf8"

{ time -p logger "Rsyslog ping"; } 2>&1 |awk '/real/ {print $2}'
