#!/bin/bash

# add to sudoers:
# daemon ALL=(root) NOEXEC: NOPASSWD: /usr/bin/fail2ban-client status, /usr/bin/fail2ban-client status *

source /usr/local/lib/collectd/_functions.sh

function extract_fail2ban_value {
    grep "${1}" <<< "${2}" | cut -d":" -f2 | xargs
}

plugin="fail2ban"
while true; do
    JAILS="$(sudo /usr/bin/fail2ban-client status 2>/dev/null | grep 'Jail list' | cut -d":" -f2 | tr ',' "\n" | xargs)"

    for j in $JAILS; do
        instance="$(echo "${j}" | tr '-' '_')"
        status="$(sudo /usr/bin/fail2ban-client status "${j}" 2>/dev/null)"

        declare -A data
        data[total_failed]=$(extract_fail2ban_value "Total failed" "${status}")
        data[currently_failed]=$(extract_fail2ban_value "Currently failed" "${status}")
        data[total_banned]=$(extract_fail2ban_value "Total banned" "${status}")
        data[currently_banned]=$(extract_fail2ban_value "Currently banned" "${status}")

        for key in "${!data[@]}"; do
            echo "PUTVAL $HOSTNAME/${plugin}-${instance}/gauge-${key} interval=$INTERVAL N:${data[$key]}"
        done

    done
    sleep "$INTERVAL"
done
