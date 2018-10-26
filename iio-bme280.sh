#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

ID="77"
NAME="bme280"

test_i2c_device "${ID}" "${NAME}"

TEM_ID="1"
HUM_ID="2"
BAR_ID="3"

mymqtt_init "${ID}" "${TEM_ID}" "${S_TEMP}" "BME280 TEMPERATURE"
mymqtt_init "${ID}" "${HUM_ID}" "${S_HUM}" "BME280 HUMIDITY"
mymqtt_init "${ID}" "${BAR_ID}" "${S_BARO}" "BME280 BAROMETER"

while true; do
    for sensor in /sys/bus/iio/devices/iio\:device*; do
        sensorname=$(cat "${sensor}/name")
        if [ "$sensorname" != "${NAME}" ]; then
            continue
        fi

        prefix="sensors-weather"
        suffix="-${sensorname}"
        declare -A data
        data[temperature]=$(echo "scale=2;$(cat ${sensor}/in_temp_input)/1000" | bc )
        data[pressure]=$(echo "scale=2;$(cat ${sensor}/in_pressure_input)*10/1" | bc)
        data[humidity]=$(echo "scale=0;$(cat ${sensor}/in_humidityrelative_input)/1" | bc)

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

        mymqtt_update "${ID}" "${TEM_ID}" "${V_TEMP}" "${data[temperature]}"
        mymqtt_update "${ID}" "${HUM_ID}" "${V_HUM}" "${data[humidity]}"
        mymqtt_update "${ID}" "${BAR_ID}" "${V_PRESSURE}" "${data[pressure]}"

    done
    sleep "$INTERVAL"
done
