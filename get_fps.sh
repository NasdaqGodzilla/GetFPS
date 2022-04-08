#!/bin/bash

# TODO: Add params to control log print
log_enable=true
log_tag=get_fps

prop_hwui_profile="debug.hwui.profile"

function import() {
    source $1 >> /dev/null
}

function log_print() {
    [[ "$log_enable" == "true" ]] || return 0
    echo -e $log_tag":\t""$@"
}

function log_err_print() {
    echo -e $log_tag"[ERR]:\t""$@"
}

function assert_hwui_profile_enabled() {
    hwui_profile_enabled=`getprop "$prop_hwui_profile"`
    [[ "$hwui_profile_enabled" == "true" ]] || return 0
    return 1
}

function calculate_fps() {
    log_print " ***** RAW PROFILE DATA ***** "
    # TODO: assign to an value.
    echo "$gfxinfo" | head -n $data_end_line | tail -n $data_total
    [[ "$enable_log" == "true" ]]
}

import utils.sh

if assert_hwui_profile_enabled; then
cat << EOF

    ---------------- ***** -----------------
    To work with dumpsys gfxinfo and retrieve profile data,
    $prop_hwui_profile must be set. And am restart may also need.
    Enable profile data by command "setprop $prop_hwui_profile true".
    Then type "am restart" to restart framework.
    ---------------- ***** -----------------

EOF
    return 1
fi

# TODO
# parse_params

resumed_pkg=`utils\:\:GetResumedActivityPkgName`
log_print "Resumed pkg: "$resumed_pkg

# TODO: Add params to assign target_pkg
target_pkg="$resumed_pkg"
log_print "Target pkg: "$target_pkg

gfxinfo=$(dumpsys gfxinfo $target_pkg)

# Find and locale the profile data
data_start="Execute"
data_end="View hierarchy:"
data_start_line=$(echo "$gfxinfo"  | grep "$data_start" -n | awk -F: '{print $1}')
data_end_line=$(echo "$gfxinfo"  | grep "$data_end" -n | awk -F: '{print $1}')
data_total=0
let data_start_line++
let data_end_line-=2
let data_total=data_end_line-data_start_line+1

log_print "Profile data line number: " "["$data_start_line", "$data_end_line"] total: " $data_total

# If you don't call am restart, there would be no data even if $hwui_profile_enabled was set.
if [ $data_start_line -lt 1 ]
then
    log_err_print "Empty profile data. Maybe profile data unavailable or am restart needed."
    return -1
fi

if [ $data_total -lt 1 ]
then
log_err_print "Empty profile data[$target_pkg]. Swipe the screen to generate."
else
    calculate_fps
fi

