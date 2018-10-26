#!/usr/bin/env bash

source /usr/local/lib/collectd/_functions.sh

ID="60"
NAME="si1145"

test_i2c_device "${ID}" "${NAME}"

UV_ID="1"
IR_ID="2"
LI_ID="3"

mymqtt_init "${ID}" "${UV_ID}" "${S_UV}" "SI1145 UV"
mymqtt_init "${ID}" "${IR_ID}" "${S_LIGHT_LEVEL}" "SI1145 IR"
mymqtt_init "${ID}" "${LI_ID}" "${S_LIGHT_LEVEL}" "SI1145 LIGHT"

while true; do
    for sensor in /sys/bus/iio/devices/iio\:device*; do
        sensorname=$(cat "${sensor}/name")
        if [ "$sensorname" != "${NAME}" ]; then
            continue
        fi

        prefix="sensors-weather"
        suffix="-${sensorname}"
        declare -A data
        data[ir]=$(cat ${sensor}/in_intensity_ir_raw)
        data[light]=$(cat ${sensor}/in_intensity_raw)
        data[uv]=$(cat ${sensor}/in_uvindex_raw)

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${prefix}/${key}${suffix} interval=$INTERVAL N:${data[$key]}"
        done

        mymqtt_update "${ID}" "${UV_ID}" "${V_UV}" "${data[uv]}"
        mymqtt_update "${ID}" "${IR_ID}" "${V_LEVEL}" "${data[ir]}"
        mymqtt_update "${ID}" "${LI_ID}" "${V_LEVEL}" "${data[light]}"

    done
    sleep "$INTERVAL"
done
