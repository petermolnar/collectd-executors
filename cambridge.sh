#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"
DOMOTICZ_PORT="${2:-8080}"
DOMOTICZ_IDX="${1:-1}"
DOMOTICZ_URL="http://${HOSTNAME}:${DOMOTICZ_PORT}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_IDX}&nvalue=0&svalue="

while true; do
    cbg="$(wget -O- -q https://www.cl.cam.ac.uk/research/dtg/weather/current-obs.txt)"

    prefix="sensors-weather"
    suffix="-cambridge"
    declare -A data
    data[temperature]=$(grep "Temperature" <<< "${cbg}" | awk '{print $2}')
    data[humidity]=$(echo "scale=0;$(grep "Humidity" <<< "${cbg}" | awk '{print $2}')/1" | bc)
    data[pressure]=$(echo "scale=2;$(grep "Pressure" <<< "${cbg}" | awk '{print $2}')/1" | bc)

    for key in "${!data[@]}"; do
        echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
    done

    domoticz_data="${data[temperature]};${data[humidity]};$(humidity_to_comfort ${data[humidity]});${data[pressure]};0"
    SEND="${DOMOTICZ_URL}${domoticz_data}"
    domoticz_send ${SEND}

    sleep "$INTERVAL"
done
