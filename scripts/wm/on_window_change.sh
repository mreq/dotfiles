#!/bin/bash
window_id=$1
window_wm_class=$( xprop -id $window_id | grep WM_CLASS | awk -F'"' '{ print $2"."$4 }' )
function wmctile {
	~/scripts/bin/wmctile $@
}


# Handle different $window_wm_class-es :)
if [[ $window_wm_class = "Msgcompose.Thunderbird" ]]; then
	# Resize new message window
	size=$( wmctrl -d | head -n 1 | grep -Eho '[0-9]{4}x[0-9]{3,4}' | tail -1 )
	width=$( echo $size | cut -d'x' -f 1 )
	height=$( echo $size | cut -d'x' -f 2 )

	if [[ $( wmctrl -lx | grep -c $window_wm_class ) == "2" ]]; then
		ids=$( wmctrl -lx | grep $window_wm_class | awk '{print $1}' )
		wmctrl -ir $( echo $ids | awk '{print $1}' ) -b remove,maximized_horz,maximized_vert -e 0,$(( $width/10 )),$(( $height/10 )),$(( $width*7/20 )),$(( $height*8/10 ))
		wmctrl -ir $( echo $ids | awk '{print $2}' ) -b remove,maximized_horz,maximized_vert -e 0,$(( $width*5/10 )),$(( $height/10 )),$(( $width*7/20 )),$(( $height*8/10 ))
	else
		wmctrl -r :ACTIVE: -b remove,maximized_horz,maximized_vert -e 0,$(( $width/10 )),$(( $height/10 )),$(( $width*8/10 )),$(( $height*8/10 ))
	fi
fi