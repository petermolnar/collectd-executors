#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"
DOMOTICZ_PORT="${2:-8080}"
DOMOTICZ_IDX="${1:-1}"
DOMOTICZ_URL="http://${HOSTNAME}:${DOMOTICZ_PORT}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_IDX}&nvalue=0&svalue="

while true; do
    ac="$(cat /sys/devices/platform/smapi/ac_connected)"
    for battery in /sys/devices/platform/smapi/BAT*; do

        if [ $(cat "${battery}/installed") -eq 0 ]; then
            continue
        fi

        prefix="thinkpad-$(basename $battery | tr '[:upper:]' '[:lower:]')"
        suffix=""
        declare -A data
        data[gauge-ac_connected]=${ac}
        data[capacity-capacity]=$(echo "scale=2;$(cat ${battery}/remaining_capacity)/1000" | bc)
        data[capacity-last_full_capacity]=$(echo "scale=2;$(cat ${battery}/remaining_capacity)/1000" | bc)
        data[count-cycles]=$(cat ${battery}/cycle_count)
        data[percent-percent]=$(cat ${battery}/remaining_percent)
        data[temperature-temperature]=$(echo "scale=2;$(cat ${battery}/temperature)/1000" | bc)
        data[voltage-voltage]=$(echo "scale=2;$(cat ${battery}/voltage)/1000" | bc)
        data[power-power]=$(echo "scale=2;$(cat ${battery}/power_now)/1000" | bc)
        data[current-current]==$(echo "scale=2;$(cat ${battery}/current_now)/1000" | bc)

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

    done

    sleep "$INTERVAL"
done
