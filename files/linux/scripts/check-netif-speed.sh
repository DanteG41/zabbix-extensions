#!/usr/bin/env bash
# Description:  check compliance with the current network interface speed to the declared.
# Author:       Lesovsky A.V.

print_usage() {
        echo "Usage:"
        echo "  ${0##*/} --discovery    discovery ACTIVE physical interfaces"
        echo "  ${0##*/} --check=eth0   check interface speed"
        exit
}

# Zabbix marks an item unsupported only when the output is exactly this
# string, and agent2 merges stderr into the item value, so the reason is
# printed for a human at a terminal only.
not_supported() {
        echo "ZBX_NOTSUPPORTED"
        [[ -t 2 && -n "$1" ]] && echo "$1" >&2
        exit 1
}

# Highest speed (Mb/s) from the ethtool block starting with label $1.
# The block ends at the next labelled line, because the trailing label
# differs between drivers and a fixed one would let the match run away
# into unrelated output such as "Current message level: 0x2000 (8192)".
max_link_mode() {
        awk -v label="$1" '
                !inBlock {
                        pos = index($0, label)
                        if (!pos) next
                        inBlock = 1
                        $0 = substr($0, pos + length(label))
                }
                /:/ { exit }
                { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+base/ && $i + 0 > max) max = $i + 0 }
                END { if (max) print max }
        '
}

first=1

command -v ethtool >/dev/null || not_supported "ethtool not found."
[[ -n $@ ]] || { print_usage; exit 1; }

physIfList=$(for interface in $(ls --color=never -d /sys/devices/pci*/*/*/net/*/ 2>/dev/null); do basename $interface; done)
physActiveIfList=$(for interface in $physIfList; do
        [[ -e /sys/class/net/$interface/operstate ]] && echo $interface $(cat /sys/class/net/$interface/operstate);
done |grep -w up |cut -d' ' -f1)

MODE=$1

case "$MODE" in
'--discovery' )
        printf "{\n";
        printf "\t\"data\":[\n\n";
        for interface in ${physActiveIfList}
        do
                [ $first != 1 ] && printf ",\n";
                first=0;
                printf "\t{\n";
                printf "\t\t\"{#PHYS_IFNAME}\":\"$interface\"\n";
                printf "\t}";
        done
        printf "\n\t]\n";
        printf "}\n";
        ;;
--check=* )
        physIfName=$(echo $1 |cut -d= -f2)
        grep -qxF "$physIfName" <<< "$physActiveIfList" || not_supported "Interface $physIfName not found or link not detected."

        ethtoolOut=$(ethtool $physIfName 2>/dev/null)
        [[ -n "$ethtoolOut" ]] || not_supported "ethtool produced no output for $physIfName."

        localCurrent=$(sed -n -E 's#^[[:space:]]*Speed:[[:space:]]*([0-9]+)Mb/s.*#\1#p' <<< "$ethtoolOut" |head -n1)
        [[ -n "$localCurrent" ]] || not_supported "could not determine current speed for $physIfName (ethtool reported no usable value)."

        # Case matters: "Advertised link modes:" does not match the partner's
        # "Link partner advertised link modes:".
        localMax=$(max_link_mode 'Advertised link modes:' <<< "$ethtoolOut")
        # With auto-negotiation off many drivers clear the advertising mask
        # ("Not reported"), leaving the hardware capability as the only
        # reference point for what this interface could have reached.
        [[ -n "$localMax" ]] || localMax=$(max_link_mode 'Supported link modes:' <<< "$ethtoolOut")
        [[ -n "$localMax" ]] || not_supported "could not determine link modes for $physIfName."

        # The partner block is absent when the partner doesn't advertise its
        # modes (auto-negotiation off on its side); the local advertisement is
        # then the only reference point left.
        remoteMax=$(max_link_mode 'Link partner advertised link modes:' <<< "$ethtoolOut")

        maxAchievable=$localMax
        [[ -n "$remoteMax" && $remoteMax -lt $maxAchievable ]] && maxAchievable=$remoteMax

        [[ $localCurrent -lt $maxAchievable ]] && { echo "$physIfName: current speed ${localCurrent}Mb/s is below maximum achievable ${maxAchievable}Mb/s"; exit 1; }

        echo OK; exit 0
;;
* ) print_usage;;
esac
