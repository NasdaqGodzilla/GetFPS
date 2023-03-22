#!/bin/bash

function utils::GetResumedActivityPkgName() {
    ret=`dumpsys activity a | grep mResumedActivity | \
        awk '{print $4}' | sed -n "s/\(.*\)\/\(.*\)/\1/g;p"`
    echo "$ret"
}

function utils_get_display_refreshrate() {
    dumpsys display | grep DisplayConfig | grep refreshRate | sed -r 's/.*refreshRate=([0-9]*).*/\1/g'
}

