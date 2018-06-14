#!/bin/bash

# Returns average time of downloading multiple documents from swift. Using the swift API.
# OpenStack details / credentials
OS_AUTH_URL="http://1.1.1.1:5000/v2.0"
OS_PASSWORD="replace_me"
OS_TENANT_NAME="replace_me"
OS_USERNAME="replace_me"

SWIFT_CONTAINER='replace_me'
TEMP_DIR='/tmp'

creating_objects() {
    dd if=/dev/urandom of=grafana-$1.file bs=1024 count=1024
}

uploading_object() {
    SWIFT_DOC_METRICS=$(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME upload $SWIFT_CONTAINER $1)
    echo $SWIFT_DOC_METRICS
}

downloading_object() {
    SWIFT_DOC_METRICS=$(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME download "$SWIFT_CONTAINER" $1)
    echo $SWIFT_DOC_METRICS
}

cleanup_object(){
    SWIFT_DOC_METRICS=$(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME delete $SWIFT_CONTAINER $1)
    echo $SWIFT_DOC_METRICS
}

reading_metrics() {
    SWIFT_METRICS_SUMMARY=("0" "0" "0" "0")
    cd $TEMP_DIR
    # loop for number
    for i in $(seq 1 $1);
        do
        creating_objects $i > /dev/null 2>&1 &
        WRITE=$(uploading_object "grafana-$i.file")
        READ=$(downloading_object "grafana-$i.file")
        REMOVE=$(cleanup_object "grafana-$i.file")

        SWIFT_DOC_METRICS_AUTH=`echo $READ | awk '{print $3}'| sed 's/[,s]//g'`
        SWIFT_DOC_METRICS_HEADERS=`echo $READ | awk '{print $5}'| sed 's/[,s]//g'`
        SWIFT_DOC_METRICS_TOTAL=`echo $READ | awk '{print $7}'| sed 's/[,s]//g'`
        SWIFT_DOC_METRICS_TRANSMISSION=`echo $READ | awk '{print $8}'| sed 's/[,s]//g'`

        #echo "Metrics on grafana-$i.file - auth:$SWIFT_DOC_METRICS_AUTH headers:$SWIFT_DOC_METRICS_HEADERS total:$SWIFT_DOC_METRICS_TOTAL transmission:$SWIFT_DOC_METRICS_TRANSMISSION MB/s"
        #Put results in array
        SWIFT_METRICS_SUMMARY[0]=$(echo "${SWIFT_METRICS_SUMMARY[0]} + $SWIFT_DOC_METRICS_AUTH" | bc)
        SWIFT_METRICS_SUMMARY[1]=$(echo "${SWIFT_METRICS_SUMMARY[1]} + $SWIFT_DOC_METRICS_HEADERS" | bc)
        SWIFT_METRICS_SUMMARY[2]=$(echo "${SWIFT_METRICS_SUMMARY[2]} + $SWIFT_DOC_METRICS_TOTAL" | bc)
        SWIFT_METRICS_SUMMARY[3]=$(echo "${SWIFT_METRICS_SUMMARY[3]} + $SWIFT_DOC_METRICS_TRANSMISSION" | bc)
    done

    # covert from float to int
    COUNTER=0
    for METRIC in "${SWIFT_METRICS_SUMMARY[@]}"
        do
        SWIFT_METRICS_SUMMARY[$COUNTER]=$(echo "scale=3; $METRIC / $1" | bc | sed -e 's/^\./0./' -e 's/^-\./-0./');
        COUNTER=$((COUNTER + 1))
    done

    echo "auth:${SWIFT_METRICS_SUMMARY[0]}ms headers:${SWIFT_METRICS_SUMMARY[1]}ms total:${SWIFT_METRICS_SUMMARY[2]}ms transmission:${SWIFT_METRICS_SUMMARY[3]}"
}

if ! which swift >/dev/null 2>&1; then
    echo "ERROR: swiftclient not found"
elif ! SWIFT_TEST=$(timeout 5 swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME list 2>/dev/null); then
    echo "ERROR: Unable to access swift"
    exit    
elif [[ $1 =~ ^[0-9]+$ ]]; then
    reading_metrics $1
else
    echo "ERROR: Provide amount of documents. Example: ./swift_check 2"
fi
