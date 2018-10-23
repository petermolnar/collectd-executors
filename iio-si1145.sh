#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"
DOMOTICZ_PORT="${2:-8080}"
DOMOTICZ_IDX="${1:-1}"
DOMOTICZ_URL="http://${HOSTNAME}:${DOMOTICZ_PORT}/json.htm?type=command&param=udevice&idx=${DOMOTICZ_IDX}&nvalue=0&svalue="

i2cdev=$(dmesg | grep 'connected i2c-tiny-usb device' | head -n1 | sed -r 's/.*\s+i2c-([0-9]+).*/\1/')
echo "si1145 0x60" > /sys/bus/i2c/devices/i2c-${i2cdev}/new_device

while true; do
    for sensor in /sys/bus/iio/devices/iio\:device*; do
        name=$(cat "${sensor}/name")
        if [ "$name" != "si1145" ]; then
            continue
        fi

        prefix="sensors-weather"
        suffix=""
        declare -A data
        data[gauge-ir]=$(cat ${sensor}/in_intensity_ir_raw)
        data[gauge-visible]=$(cat ${sensor}/in_intensity_raw)
        data[gauge-uv]=$(cat ${sensor}/in_uvindex_raw)

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

    done
    sleep "$INTERVAL"
done
