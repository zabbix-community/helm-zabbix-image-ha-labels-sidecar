#!/bin/bash

# we assume our pod is called like the hostname, which is default
pod_name=${HOSTNAME}
port_number=${ZBX_LISTENPORT:-10051}
label_name="zabbix.com/server-ha-role"
sleep_time=5

update_label() {
    current_value=$1
    new_value=$2
    if [ "${current_value}" != "${new_value}" ]; then
        echo "setting label ${label_name} from value ${current_value} to ${new_value}"
        kubectl label pod ${pod_name} "${label_name}"="${new_value}" --overwrite
    fi
}

while true;
do
    now=$(date +%s)
    if [[ -z "$last_label_read" || $((now - last_label_read)) -gt 300 ]]; then
        label_value=$(kubectl get pod ${pod_name} -o json | jq -r ".metadata.labels[\"${label_name}\"]")
        last_label_read=${now}
        echo "got label value ${label_value}"
    fi

    # check whether listen-port is open
    if { echo > /dev/tcp/localhost/${port_number}; } 2>/dev/null; then
        echo "port ${port_number} is open"
        update_label "${label_value}" "active"
    else:
        echo "port ${port_number} is closed"
        update_label "${label_value}" "standby"
    fi
    sleep ${sleep_time}
done
