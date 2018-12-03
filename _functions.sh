#!/usr/bin/env bash

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

MQTT_PORT="${COLLECTD_MQTTPORT:-1883}"
MQTT_HOST="${COLLECTD_MQTTHOST:-$(hostname -f)}"
MQTT_TOPIC="${COLLECTD_MQTTOPIC:-domoticz/in/MyMQTT}"

I2CBUS=$(/usr/sbin/i2cdetect -l | grep i2c-tiny-usb | sed -r 's/^i2c-([0-9]+).*/\1/')

S_DOOR=0
S_MOTION=1
S_SMOKE=2
S_BINARY=3
S_DIMMER=4
S_COVER=5
S_TEMP=6
S_HUM=7
S_BARO=8
S_WIND=9
S_RAIN=10
S_UV=11
S_WEIGHT=12
S_POWER=13
S_HEATER=14
S_DISTANCE=15
S_LIGHT_LEVEL=16
S_ARDUINO_NODE=17
S_ARDUINO_REPEATER_NODE=18
S_LOCK=19
S_IR=20
S_WATER=21
S_AIR_QUALITY=22
S_CUSTOM=23
S_DUST=24
S_SCENE_CONTROLLER=25
S_RGB_LIGHT=26
S_RGBW_LIGHT=27
S_COLOR_SENSOR=28
S_HVAC=29
S_MULTIMETER=30
S_SPRINKLER=31
S_WATER_LEAK=32
S_SOUND=33
S_VIBRATION=34
S_MOISTURE=35
S_INFO=36
S_GAS=37
S_GPS=38
S_WATER_QUALITY=39

V_TEMP=0
V_HUM=1
V_STATUS=2
V_PERCENTAGE=3
V_PRESSURE=4
V_FORECAST=5
V_RAIN=6
V_RAINRATE=7
V_WIND=8
V_GUST=9
V_DIRECTION=10
V_UV=11
V_WEIGHT=12
V_DISTANCE=13
V_IMPEDANCE=14
V_ARMED=15
V_TRIPPED=16
V_WATT=17
V_KWH=18
V_SCENE_ON=19
V_SCENE_OFF=20
V_HVAC_FLOW_STATE=21
V_HVAC_SPEED=22
V_LIGHT_LEVEL=23
V_UP=29
V_DOWN=30
V_STOP=31
V_IR_SEND=32
V_IR_RECEIVE=33
V_FLOW=34
V_VOLUME=35
V_LOCK_STATUS=36
V_LEVEL=37
V_VOLTAGE=38
V_CURRENT=39
V_RGB=40
V_RGBW=41
V_ID=42
V_UNIT_PREFIX=43
V_HVAC_SETPOINT_COOL=44
V_HVAC_SETPOINT_HEAT=45
V_HVAC_FLOW_MODE=46
V_TEXT=47
V_CUSTOM=48
V_POSITION=49
V_IR_RECORD=50
V_PH=51
V_ORP=52
V_EC=53
V_VAR=54
V_VA=55
V_POWER_FACTOR=56

function test_i2c_device {
    if [ ! -d "/sys/bus/i2c/devices/i2c-${I2CBUS}/${I2CBUS}-00${1}" ]; then
        echo "run ${2} 0x${1} > /sys/bus/i2c/devices/i2c-${I2CBUS}/new_device"
        exit 2
    fi
}

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

function mymqtt_test {
    if [ ! -x "$(which mosquitto_pub)" ]; then
        >&2 echo "mosquitto_pub command is not executable or missing"
        exit 2
    fi

    if ! nc -z ${MQTT_HOST} ${MQTT_PORT}; then
        exit 0
    fi

}

function mymqtt_init {
    mymqtt_test
    mosquitto_pub -t "${MQTT_TOPIC}/${1}/${2}/0/0/${3}" -m "${4}"
}


function mymqtt_update {
    mymqtt_test
    mosquitto_pub -t "${MQTT_TOPIC}/${1}/${2}/1/0/${3}" -m "${4}"
}

function mymqtt_battery {
    mymqtt_test
    mosquitto_pub -t "${MQTT_TOPIC}/${1}/${2}/3/0/0" -m "${3}"
}
