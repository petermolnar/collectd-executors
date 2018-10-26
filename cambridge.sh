#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

ID="99"

TEM_ID="1"
HUM_ID="2"
BAR_ID="3"
RAIN_ID="4"
SUN_ID="5"

mymqtt_init "${ID}" "${TEM_ID}" "${S_TEMP}" "CBG TEMPERATURE"
mymqtt_init "${ID}" "${HUM_ID}" "${S_HUM}" "CBG HUMIDITY"
mymqtt_init "${ID}" "${BAR_ID}" "${S_BARO}" "CBG BAROMETER"
mymqtt_init "${ID}" "${RAIN_ID}" "${S_RAIN}" "CBG RAIN"
#mymqtt_init "${ID}" "${SUN_ID}" "${S_CUSTOM}" "CBG SUN"

while true; do
    cbg="$(wget -O- -q https://www.cl.cam.ac.uk/research/dtg/weather/current-obs.txt)"
    #Cambridge Computer Laboratory Rooftop Weather at 09:03 AM on 26 Oct 18:

    #Temperature:  7.6 C
    #Pressure:     1010 mBar
    #Humidity:     87 %
    #Dewpoint:     5.6 C
    #Wind:         4 knots from the W
    #Sunshine:     0.0 hours (today)
    #Rainfall:     0.0 mm since midnight

    #Summary:      very humid, cold, light winds


    prefix="sensors-weather"
    suffix="-cambridge"
    declare -A data
    data[temperature]=$(grep "Temperature" <<< "${cbg}" | awk '{print $2}')
    data[humidity]=$(echo "scale=0;$(grep "Humidity" <<< "${cbg}" | awk '{print $2}')/1" | bc)
    data[pressure]=$(echo "scale=2;$(grep "Pressure" <<< "${cbg}" | awk '{print $2}')/1" | bc)
    data[rain]=$(echo "scale=2;$(grep "Rainfall" <<< "${cbg}" | awk '{print $2}')/1" | bc)
    data[sunshine]=$(echo "scale=2;$(grep "Rainfall" <<< "${cbg}" | awk '{print $2}')/1" | bc)

    for key in "${!data[@]}"; do
        echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
    done

    mymqtt_update "${ID}" "${TEM_ID}" "${V_TEMP}" "${data[temperature]}"
    mymqtt_update "${ID}" "${HUM_ID}" "${V_HUM}" "${data[humidity]}"
    mymqtt_update "${ID}" "${BAR_ID}" "${V_PRESSURE}" "${data[pressure]}"
    mymqtt_update "${ID}" "${RAIN_ID}" "${V_RAIN}" "${data[rain]}"
    #mymqtt_update "${ID}" "${SUN_ID}" "${V_VAR1}" "${data[sunshine]}"

    sleep "$INTERVAL"
done
