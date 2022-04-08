#!/bin/bash

log_enable=false
log_tag=get_fps

print_aver_total=false

param_target_pkgname=
profile_raw_data=

prop_hwui_profile="debug.hwui.profile"

function import() {
    source $1 >> /dev/null
}

function log_print() {
    [[ "$log_enable" == "true" ]] || return 0
    echo -e $log_tag":\t""$@"
}

function log_println() {
    log_print "$@\n"
}

function log_err_print() {
    echo -e $log_tag"[ERR]:\t""$@"
}

function help() {
cat << EOF
Usage: source get_fps.sh [OPTION]
Get FPS by calculate profile data retrieved from dumpsys gfxinfo.

  -h     display this help and exit
  -p     package name to dump. default: current top resumed package
  -d     enable log printing. default: just print FPS.
  -t     print average total elapsed time instead of FPS.

Example:
  source get_fps.sh                             Print FPS for current top resumed package.
  source get_fps.sh -p com.android.launcher3    Print FPS for selected package.

INFO:
  The calculation from gfxinfo profile data does not work if app draws without hwui.
  So it only works in when app draws with hardward accelerate.
  There are no available profile data if app does not call performTraversals. It means no frame refresh and zero FPS.

  Besides, The frame rate that calculate with 1000 divided by the average elapsed time is not always exactly the real FPS.
  Such as, under the simple drawing and less workload, the calculation result will obviously higher than normal case
  and especially heavy-load case. The high FPS still finally limit under display.
EOF
}

function assert_hwui_profile_enabled() {
    hwui_profile_enabled=`getprop "$prop_hwui_profile"`
    [[ "$hwui_profile_enabled" == "true" ]] || return 0
    return 1
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

OPTIND=1
while getopts thdp: opt
do
    case "$opt" in
        d)
            log_enable=true
            log_print "Enable log printing"
            ;;
        p)
            param_target_pkgname="${OPTARG}"
            log_print "Target: "$param_target_pkgname
            ;;
        t)
            print_aver_total=true
            log_print "Enable print_aver_total"
            ;;
        h)
            help
            return
            ;;
        *)
            log_err_print "Unknown option $OPTARG"
            help
            return
            ;;
    esac
done

function calculate_framerate() {
    if [ `echo "$aver_total <= 0.01" | bc` -eq 1 ]; then
        fps=0
        return
    fi

    fps=`echo "1000/$aver_total" | bc`
}

function calculate_average() {
    ret=$( \
        echo -e "$profile_raw_data" | awk -v log_enable="$log_enable" -v log_tag="$log_tag" '
            {
                sum_draw+=$1
                sum_prepare+=$2
                sum_process+=$3
                sum_execute+=$4
            }
            END {
                aver_draw=sum_draw/NR
                aver_prepare=sum_prepare/NR
                aver_process=sum_process/NR
                aver_execute=sum_execute/NR

                printf("NR=%d sum_draw=%2.2f aver_draw=%2.2f sum_prepare=%2.2f \
                    aver_prepare=%2.2f sum_process=%2.2f aver_process=%2.2f \
                    sum_execute=%2.2f aver_execute=%2.2f",
                    NR, sum_draw, aver_draw, sum_prepare, aver_prepare,
                    sum_process, aver_process, sum_execute, aver_execute);
            }'
    )

    eval $(echo -e "$ret" | awk 'BEGIN{RS=" "} /aver_draw/')
    eval $(echo -e "$ret" | awk 'BEGIN{RS=" "} /aver_prepare/')
    eval $(echo -e "$ret" | awk 'BEGIN{RS=" "} /aver_process/')
    eval $(echo -e "$ret" | awk 'BEGIN{RS=" "} /aver_execute/')
    aver_total=`echo "$aver_draw+$aver_prepare+$aver_process+$aver_execute" | bc`

    log_print "calculate_average: " $ret
    log_print "Aver: $aver_draw $aver_prepare $aver_process $aver_execute"
    log_print "aver_total: " $aver_total
}

function calculate_fps_impl() {
    calculate_average
    calculate_framerate
}

function calculate_fps() {
    profile_raw_data=`echo -e "$gfxinfo" | head -n $data_end_line | tail -n $data_total`
    log_print "***** RAW PROFILE DATA *****"
    log_print "$profile_raw_data"
    calculate_fps_impl
}

function calculate_done() {
    [[ "$print_aver_total" == "true" ]] &&
        echo "Average elapsed $aver_total ms" ||
        # echo "$PREFIX$fps$SUFFIX"
        echo "$1$fps$2"
}

resumed_pkg=`utils\:\:GetResumedActivityPkgName`
log_print "Resumed pkg: "$resumed_pkg

[[ ! -z "$param_target_pkgname" ]] && \
    target_pkg="$param_target_pkgname" || \
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

fps=0
aver_draw=0
aver_prepare=0
aver_process=0
aver_execute=0
aver_total=0
if [ $data_total -lt 1 ]
then
log_print "Empty profile data[$target_pkg]. Swipe the screen to generate."
calculate_done "FPS: "
else
    calculate_fps
    calculate_done "FPS: "
fi

