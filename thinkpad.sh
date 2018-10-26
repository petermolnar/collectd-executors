#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

ID="90"

POWER_ID="1"
CURRENT_ID="2"
VOLTAGE_ID="3"
AC_ID="4"
TEM_ID="5"

mymqtt_init "${ID}" "${POWER_ID}" "${S_POWER}" "THINKPAD POWER"
mymqtt_init "${ID}" "${CURRENT_ID}" "${S_MULTIMETER}" "THINKPAD CURRENT"
mymqtt_init "${ID}" "${VOLTAGE_ID}" "${S_MULTIMETER}" "THINKPAD VOLTAGE"
mymqtt_init "${ID}" "${AC_ID}" "${S_BINARY}" "THINKPAD AC"
mymqtt_init "${ID}" "${TEM_ID}" "${S_TEMP}" "THINKPAD TEMPERATURE"

while true; do
    ac="$(cat /sys/devices/platform/smapi/ac_connected)"

    for battery in /sys/devices/platform/smapi/BAT*; do

        if [ $(cat "${battery}/installed") -eq 0 ]; then
            continue
        fi

        bname="$(basename $battery | tr '[:upper:]' '[:lower:]')"
        ID=$(($ID+${bname/bat/}))


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
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

        mymqtt_update "${ID}" "${POWER_ID}" "${V_WATT}" "${data[power-power]}"
        mymqtt_battery "${ID}" "${POWER_ID}" "${data[percent-percent]}"

        mymqtt_update "${ID}" "${CURRENT_ID}" "${V_CURRENT}" "${data[current-current]}"
        mymqtt_battery "${ID}" "${CURRENT_ID}" "${data[percent-percent]}"

        mymqtt_update "${ID}" "${VOLTAGE_ID}" "${V_VOLTAGE}" "${data[voltage-voltage]}"
        mymqtt_battery "${ID}" "${VOLTAGE_ID}" "${data[percent-percent]}"

        mymqtt_update "${ID}" "${TEM_ID}" "${V_TEMP}" "${data[temperature-temperature]}"
        mymqtt_battery "${ID}" "${TEM_ID}" "${data[percent-percent]}"

        mymqtt_update "${ID}" "${AC_ID}" "${V_STATUS}" "${data[gauge-ac_connected]}"
        mymqtt_battery "${ID}" "${AC_ID}" "${data[percent-percent]}"


    done

    ## fan
    #prefix="thinkpad-fan"
    #suffix=""
    #declare -A data
    #status="$(cat /proc/acpi/ibm/fan)"
    #data[fanspeed-speed]=$(grep 'speed:' <<< "$status"  | awk '{print $2}')
    #data[gauge-fanlevel]=$(grep 'level:' <<< "$status"  | awk '{print $2}')
    #for key in "${!data[@]}"; do
        #value=${data[$key]}
        #echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"

        #if [ ! ${idx[$key]+test} ]; then
            #continue
        #fi

        #sensor=${idx[$key]}
        #SEND="${DOMOTICZ_URL}&idx=${sensor}&battery=${data[percent-percent]}&svalue=${value}"
        #domoticz_send ${SEND}
    #done

    sleep "$INTERVAL"
done
