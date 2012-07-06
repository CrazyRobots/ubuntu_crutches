#!/bin/bash
#The scipt connects to VPN over WiFi network using Network Manager
#console utility nmcli.
#
#NM does not automatically reconnect to two networks, so
#I use this script after Ubuntu wakes up.


#When launching after power manage event (first argument is set)
#we only need to work if the computer is resuming, not suspending. 
#In such cases we will have 'resume' or 'thaw' in first argument
#for waking up and resuming from hibernation accordingly.                  
if [ $1 ] && ! ( [ "$1" == 'resume' -o "$1" == 'thaw' ] )
then
    exit 0;
fi;

#nmcli operates connections by their id's (which you can see
#in the NM's drop-down menu) and by uuid, which can be acquired with
#nmcli con status id <ID> 
#We will use the id's as the shortest of two.

alert 'Insert IDs for the connections above and remove this line!' && exit 1;
#WiFi connection id
wifi_id=""
#VPN connection id
vpn_id=""

temp_log="/run/shm/connect_$$.tmp";
echo '' > ${temp_log}
exec &> $temp_log

#All the debug info will be put here if script fails.
log="/var/log/connect"

attempts=20

sleep_period=3

#nm-applet wakes up in some weird condition
#with all the interfaces unmanaged
service network-manager restart

nm_status=`nmcli nm status`
#Waiting Network Manager to start.
while ! (nmcli --fields RUNNING nm status | grep -q 'running')
do 
    echo "[`date -R`]"' NetworkManager seems not running, waiting...'
    sleep 1; 
done;

#Checking that WiFi is enabled.
#If not, enabling.

if ! (nmcli --fields WIFI nm status | grep -q 'enabled')
then
    echo "[`date -R`]"'WiFi disabled, enabling.'
    nmcli nm wifi on;
fi;

#Connecting to the WiFi.

attempts_left=${attempts}
echo "[`date -R`]""WiFi: "
while ! (nmcli con status id ${wifi_id} | grep 'activated') && [ $attempts_left -gt 0 ]
do
    #nmcli here have an annoying tendency to freeze, so we'll limit it's running time to ${sleep_period} seconds            
    timeout ${sleep_period} nmcli con up id ${wifi_id}
    attempts_left=$(( --attempts_left ))
    [ ${attempts_left} -ne 0 ] && echo "[`date -R`]""Re-attempting WiFi connection in ${sleep_period} second — ${attempts_left} attempts left..."
    sleep ${sleep_period};
done;
nmcli con status id ${wifi_id} &>/dev/null
wifi_connected=$(( ! $? ))

#Connecting to the VPN.
attempts_left=${attempts}
echo "[`date -R`]""VPN : "
while ! (nmcli con status id ${vpn_id} | grep 'activated') && [ $wifi_connected -eq 1 ] && [ $attempts_left -gt 0 ]
do
    #nmcli here have an annoying tendency to freeze, so we'll limit it's running time to ${sleep_period} seconds
    timeout ${sleep_period} nmcli con up id ${vpn_id}
    attempts_left=$(( --attempts_left ))
    [ ${attempts_left} -ne 0 ] && echo "[`date -R`]""Re-attempting VPN connection in ${sleep_period} second — ${attempts_left} attempts left..."
    sleep ${sleep_period};
done;
nmcli con status id ${vpn_id} &>/dev/null
vpn_connected=$(( ! $? ))

if [ ${wifi_connected} -ne 1 -o ${vpn_connected} -ne 1 ]
then
    #Save log
    date -R > ${log};
    cat ${temp_log} >> ${log};
fi;

#Cleanup
rm -f ${temp_log}