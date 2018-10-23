#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"
DOMOTICZ_PORT="${2:-8080}"
DOMOTICZ_IDX="${1:-1}"
DOMOTICZ_URL="http://${HOSTNAME}:${DOMOTICZ_PORT}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_IDX}&nvalue=0&svalue="

i2cdev=$(dmesg | grep 'connected i2c-tiny-usb device' | head -n1 | sed -r 's/.*\s+i2c-([0-9]+).*/\1/')
echo "bme280 0x77" > /sys/bus/i2c/devices/i2c-${i2cdev}/new_device

while true; do
    for sensor in /sys/bus/iio/devices/iio\:device*; do
        name=$(cat "${sensor}/name")
        if [ "$name" != "bme280" ]; then
            continue
        fi

        prefix="sensors-weather"
        suffix="-${name}"
        declare -A data
        data[temperature]=$(echo "scale=2;$(cat ${sensor}/in_temp_input)/1000" | bc )
        data[pressure]=$(echo "scale=2;$(cat ${sensor}/in_pressure_input)*10/1" | bc)
        data[humidity]=$(echo "scale=0;$(cat ${sensor}/in_humidityrelative_input)/1" | bc)

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

        domoticz_data="${data[temperature]};${data[humidity]};$(humidity_to_comfort ${data[humidity]});${data[pressure]};0"
        SEND="${DOMOTICZ_URL}${domoticz_data}"
        domoticz_send ${SEND}

    done
    sleep "$INTERVAL"
done
