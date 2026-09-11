#!/bin/sh

STATUS_FILE="${1:-/run/ptpd2.status}"

unsupported()
{
    printf '%s\n' "ZBX_NOTSUPPORTED"
    exit 0
}

if [ ! -r "$STATUS_FILE" ]; then
    unsupported
fi

mtime=$(stat -c '%Y' "$STATUS_FILE" 2>/dev/null) || unsupported

case "$mtime" in
    ''|*[!0-9]*)
        unsupported
        ;;
esac

now=$(date +%s) || unsupported

status_age=$((now - mtime))

if [ "$status_age" -lt 0 ]; then
    status_age=0
fi

content=$(cat "$STATUS_FILE" 2>/dev/null) || unsupported

case "$content" in
    *"Offset from Master :"*) ;;
    *) unsupported ;;
esac

# Offset from Master : -0.000038198 s, mean  0.000027249 s, dev  0.000418547 s
#
# $5  = offset
# $8  = mean
offset=$(printf '%s\n' "$content" |
    awk '/^Offset from Master[[:space:]]*:/ {
        print $5
        exit
    }')

mean_offset=$(printf '%s\n' "$content" |
    awk '/^Offset from Master[[:space:]]*:/ {
        print $8
        exit
    }')

# Port state        : PTP_SLAVE
state=$(printf '%s\n' "$content" |
    awk -F':' '/^Port state[[:space:]]*:/ {
	gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }')

# Clock status      : in control
clock_status=$(printf '%s\n' "$content" |
    awk -F':' '/^Clock status[[:space:]]*:/ {
	gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }')

# Значения по умолчанию для неподдерживаемых отдельных метрик.
offset_ms="ZBX_NOTSUPPORTED"
mean_offset_ms="ZBX_NOTSUPPORTED"

# Проверяем offset и переводим секунды -> миллисекунды.
if printf '%s\n' "$offset" |
    grep -Eq '^-?[0-9]+([.][0-9]+)?([eE][-+]?[0-9]+)?$'
then
    offset_ms=$(awk -v v="$offset" '
        BEGIN {
            printf "%.6f", v * 1000
        }
    ')
fi

# Проверяем mean offset и переводим секунды -> миллисекунды.
if printf '%s\n' "$mean_offset" |
    grep -Eq '^-?[0-9]+([.][0-9]+)?([eE][-+]?[0-9]+)?$'
then
    mean_offset_ms=$(awk -v v="$mean_offset" '
        BEGIN {
            printf "%.6f", v * 1000
        }
    ')
fi

[ -n "$state" ] || state="ZBX_NOTSUPPORTED"
[ -n "$clock_status" ] || clock_status="ZBX_NOTSUPPORTED"

json_escape()
{
    printf '%s' "$1" |
        sed 's/\\/\\\\/g; s/"/\\"/g'
}

state=$(json_escape "$state")
clock_status=$(json_escape "$clock_status")

printf '{'
printf '"offset_ms":%s,' "$offset_ms"
printf '"mean_offset_ms":%s,' "$mean_offset_ms"
printf '"state":"%s",' "$state"
printf '"clock_status":"%s",' "$clock_status"
printf '"status_age_sec":%s' "$status_age"
printf '}\n'
