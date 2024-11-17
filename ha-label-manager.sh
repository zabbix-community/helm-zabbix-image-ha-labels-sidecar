#!/bin/bash

# we assume our pod is called like the hostname, which is default
pod_name=${HOSTNAME}
port_number=${ZBX_LISTENPORT:-10051}
label_name=${LABEL_NAME}
sleep_time=5

log() {
    msg=$1
    ts=$(date +"%Y-%m-%d %h:%m:%s")
    echo "${ts} ${msg}"
}

log "start label manager with label name ${label_name}"

update_label() {
    current_value=$1
    new_value=$2
    if [ "${current_value}" != "${new_value}" ]; then
        log "setting label ${label_name} from value ${current_value} to ${new_value}"
        kubectl label pod ${pod_name} "${label_name}"="${new_value}" --overwrite
    fi
}

get_nr_zabbix_processes() {
    nr=$(ps axu | grep zabbix_server | grep -v grep | wc -l)
    if [ -z "${nr}" ]; then
        nr=0
    fi
    return ${nr}
}


while true;
do
    now=$(date +%s)
    if [[ -z "$last_label_read" || $((now - last_label_read)) -gt 300 ]]; then
        label_value=$(kubectl get pod ${pod_name} -o json | jq -r ".metadata.labels[\"${label_name}\"]")
        last_label_read=${now}
        log "got label value ${label_value} from Kubernetes API"
    fi

    get_nr_zabbix_processes
    nr=$?

    # check whether listen-port is open
    if [ ${nr} -gt 5 ]; then
        log "there are ${nr} zabbix server processes running (>5), this is the active node"
        update_label "${label_value}" "active"
        label_value="active"
    else
        log "there are ${nr} zabbix server processes running (<=5), this is a standby node"
        update_label "${label_value}" "standby"
        label_value="standby"
    fi
    sleep ${sleep_time}
done
