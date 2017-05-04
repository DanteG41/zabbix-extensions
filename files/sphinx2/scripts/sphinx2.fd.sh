#!/bin/bash
# Author:       Abdulbjarov R.A.

readlink /proc/$(</home/index/sphinx/$1/pid/searchd.pid)/fd/* 2>/dev/null |grep -c ^"${2/regular/\/}"
