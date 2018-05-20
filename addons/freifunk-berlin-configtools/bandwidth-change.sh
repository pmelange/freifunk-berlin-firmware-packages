#!/bin/sh
# This program should change bandwidth settings on freifunk routers
# Copyright (C) 2018 holger@freifunk-berlin
# inspired by depricated https://github.com/freifunk-berlin/firmware-packages/commit/3a923a89e705da88bd44bb78d4ebfa6655b3960e
#

# display current settings:
show_settings() {
  echo 'current settings'
  usersBandwidthDown=$(uci get ffwizard.settings.usersBandwidthDown)
  usersBandwidthUp=$(uci get ffwizard.settings.usersBandwidthUp)
  echo " userdown $(( $usersBandwidthDown * 1000))"
  echo " userup   $(( $usersBandwidthUp * 1000))"
  echo " qosdown  $(uci get qos.ffuplink.download)"
  echo " qosup    $(uci get qos.ffuplink.upload)"
}

AUTOCOMMIT="yes"
OPERATION="set"

while getopts "snu:d:" option; do
        case "$option" in
                d)
                        DOWNSPEED="${OPTARG}"
                        ;;
                u)
                        UPSPEED="${OPTARG}"
                        ;;
                n)
                        AUTOCOMMIT="no"
                        ;;
                s)
                        OPERATION="show"
                        ;;
                *)
                        echo "Invalid argument '-$OPTARG'."
                        exit 1
                        ;;    
        esac              
done        
shift $((OPTIND - 1))

if [ ${OPERATION} == "set" ]; then
		[ -z ${DOWNSPEED} ] && echo "value missing for desiredqos" && exit 1; 
		[ -z ${UPSPEED} ] && echo "value missing for desiredqos" && exit 1;
fi

# should this script run?
if [ "$(uci get ffwizard.settings.sharenet 2> /dev/null)" == "0" ]; then
    echo 'dont share my internet' && exit 0
	elif [ "$(uci get ffwizard.settings.sharenet 2> /dev/null)" == "1" ]; then
    		echo 'share my internet'
	else
		echo 'sharenet value unknown' && exit 1
fi
# can we change olsrd file?
if [ -e /etc/config/olsrd ]; then
		echo 'file olsrd found' 
	else 
		echo 'file olsrd not found' && exit 1
fi

show_settings

desiredqosdown=${DOWNSPEED}
desiredqosup=${UPSPEED}

echo desiredqosdown $desiredqosdown
echo desiredqosup $desiredqosup
# change olsrd-settings
if [ ${OPERATION} == "set" ]; then
	sed -i -e "s/$(uci get qos.ffuplink.upload) $(uci get qos.ffuplink.download)/$desiredqosup $desiredqosdown/g" /etc/config/olsrd
fi
	echo 'uci commit qos';
	uci set qos.ffuplink.download=$desiredqosdown;
	uci set qos.ffuplink.upload=$desiredqosup;
	uci set ffwizard.settings.usersBandwidthDown=$desiredqosdown;
	uci set ffwizard.settings.usersBandwidthUp=$desiredqosup;
# shall I commit changes? Yes, when called by hand.
if [ ${AUTOCOMMIT} == "yes" ];  then
	uci commit qos.ffuplink;
	uci commit ffwizard.settings;
	/etc/init.d/olsrd restart
else 
	echo 'uci dont commit qos'
	
fi


exit 0