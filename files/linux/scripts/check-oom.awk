BEGIN {
	COUNT=0
	TIME=0
	getline OFFSET<"/run/zabbix/offset.tmp"
	if (OFFSET !~ "[0-9]+$") {
		OFFSET=0
	}
}
 
{
	gsub("[][]","",$1)
	if ($1+0>OFFSET+0 && $1 ~ "[0-9]+$" && $0 ~ "Out of memory") {
		COUNT++
		TIME=$1
	}
}
 
END {
	print COUNT
	if (COUNT != 0) {
		print TIME>"/run/zabbix/offset.tmp"
	}
}
