#!/usr/bin/env bash

function humidity_to_comfort {
    hum=$(echo "scale=0;$1/1" | bc)

    if [[ $hum -lt 30 ]]; then
        COMFORT=2
    elif [[ $hum -lt 40 ]]; then
        COMFORT=0
    elif [[ $hum -lt 60 ]]; then
        COMFORT=1
    else
        COMFORT=3
    fi

    echo $COMFORT
}

function domoticz_send {
    SEND="${1}"
    if nc -z ${HOSTNAME} ${DOMOTICZ_PORT}; then
        curl -s -H "Accept: application/json" "$SEND" >/dev/null
    else
        >&2 echo "domoticz can't be reaced at ${HOSTNAME} ${DOMOTICZ_PORT}"
    fi
}
