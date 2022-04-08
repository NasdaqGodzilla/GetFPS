#!/bin/bash

function utils::GetResumedActivityPkgName() {
    ret=`dumpsys activity a | grep mResumedActivity | \
        awk '{print $4}' | sed -n "s/\(.*\)\/\(.*\)/\1/g;p"`
    echo "$ret"
}

