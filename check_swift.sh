#!/bin/bash

# Returns average time of downloading multiple documents from swift. Using the swift API.
# OpenStack details / credentials
OS_AUTH_URL="http://1.1.1.1:5000/v2.0"
OS_PASSWORD="replace_me"
OS_TENANT_NAME="replace_me"
OS_USERNAME="replace_me"

SWIFT_CONTAINER='replace_me'
TEMP_DIR='/tmp'

reading_objects() {
    SWIFT_DOCS=($(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME list $SWIFT_CONTAINER | head -$1 | sed 's/:.*//'))

    SWIFT_METRICS_SUMMARY=("0" "0" "0")

    for DOC in "${SWIFT_DOCS[@]}"
        do
        SWIFT_DOC_METRICS=$(swift --os-auth-url $OS_AUTH_URL --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-tenant-name $OS_TENANT_NAME download "$SWIFT_CONTAINER" "$DOC" -o "$TEMP_DIR/$DOC")

        SWIFT_DOC_METRICS_AUTH=`echo $SWIFT_DOC_METRICS | awk '{print $3}'| sed 's/[,s]//g'`
        SWIFT_DOC_METRICS_HEADERS=`echo $SWIFT_DOC_METRICS | awk '{print $5}'| sed 's/[,s]//g'`
        SWIFT_DOC_METRICS_TOTAL=`echo $SWIFT_DOC_METRICS | awk '{print $7}'| sed 's/[,s]//g'`

#        echo "Metrics on $DOC - auth:$SWIFT_DOC_METRICS_AUTH headers:$SWIFT_DOC_METRICS_HEADERS total:$SWIFT_DOC_METRICS_TOTAL"

        #ARRAY
        SWIFT_METRICS_SUMMARY[0]=$(echo "${SWIFT_METRICS_SUMMARY[0]} + $SWIFT_DOC_METRICS_AUTH" | bc)
        SWIFT_METRICS_SUMMARY[1]=$(echo "${SWIFT_METRICS_SUMMARY[1]} + $SWIFT_DOC_METRICS_HEADERS" | bc)
        SWIFT_METRICS_SUMMARY[2]=$(echo "${SWIFT_METRICS_SUMMARY[2]} + $SWIFT_DOC_METRICS_TOTAL" | bc)
    done

    # covert from float to int
    COUNTER=0
    for METRIC in "${SWIFT_METRICS_SUMMARY[@]}"
        do
        SWIFT_METRICS_SUMMARY[$COUNTER]=$(echo "scale=3; $METRIC / $1" | bc | sed -e 's/^\./0./' -e 's/^-\./-0./');
        COUNTER=$((COUNTER + 1))
    done

#    echo "Average metrics on sum over $1 documents - auth:${SWIFT_METRICS_SUMMARY[0]}ms headers:${SWIFT_METRICS_SUMMARY[1]}ms total:${SWIFT_METRICS_SUMMARY[2]}ms"
    echo "auth:${SWIFT_METRICS_SUMMARY[0]}ms headers:${SWIFT_METRICS_SUMMARY[1]}ms total:${SWIFT_METRICS_SUMMARY[2]}ms"
}

if [[ $1 =~ ^[0-9]+$ ]]; then
    reading_objects $1
else
    echo "ERROR: Provide amount of documents. Example: ./swift_check 2"
fi
