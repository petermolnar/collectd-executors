#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"
DOMOTICZ_PORT="${2:-8080}"
DOMOTICZ_IDX="${1:-1}"
DOMOTICZ_URL="http://${HOSTNAME}:${DOMOTICZ_PORT}/json.htm?type=command&param=udevice"

IFS=';' read -ra KEYVALS <<< "${DOMOTICZ_IDX}"
declare -A idx
for item in "${KEYVALS[@]}"; do
    idx[${item%=*}]=${item##*=}
done

while true; do

    # battery
    ac="$(cat /sys/devices/platform/smapi/ac_connected)"
    for battery in /sys/devices/platform/smapi/BAT*; do

        if [ $(cat "${battery}/installed") -eq 0 ]; then
            continue
        fi

        bname="$(basename $battery | tr '[:upper:]' '[:lower:]')"
        prefix="thinkpad-${bname}"
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
        data[current-current]=$(echo "scale=2;$(cat ${battery}/current_now)/1000" | bc)

        for key in "${!data[@]}"; do
            value=${data[$key]}
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${value}"

            if [ ! ${idx[$key]+test} ]; then
                continue
            fi

            sensor=${idx[$key]}
            SEND="${DOMOTICZ_URL}&idx=${sensor}&battery=${data[percent-percent]}"
            if grep -q "ac_connected" <<< "${key}"; then
                svalue="ONLINE"
                if [ "$value" == "0" ]; then
                    value=4
                    svalue="OFFLINE"
                fi
                SEND="${SEND}&nvalue=${value}&svalue=${svalue}"
            else
                SEND="${SEND}&nvalue=0&svalue=${value}"
            fi
            domoticz_send ${SEND}
        done
    done

    # fan
    prefix="thinkpad-fan"
    suffix=""
    declare -A data
    status="$(cat /proc/acpi/ibm/fan)"
    data[fanspeed-speed]=$(grep 'speed:' <<< "$status"  | awk '{print $2}')
    data[gauge-fanlevel]=$(grep 'level:' <<< "$status"  | awk '{print $2}')
    for key in "${!data[@]}"; do
        value=${data[$key]}
        echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"

        if [ ! ${idx[$key]+test} ]; then
            continue
        fi

        sensor=${idx[$key]}
        SEND="${DOMOTICZ_URL}&idx=${sensor}&battery=${data[percent-percent]}&svalue=${value}"
        domoticz_send ${SEND}
    done

    sleep "$INTERVAL"
done
