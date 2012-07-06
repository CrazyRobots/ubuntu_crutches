#!/bin/bash
#The script disables acpi wakeup events for
#all the input devices that often generates
#'poltergeist' wakeups.
#Run it when system starts — /etc/init.d or /etc/rc.local

if [ -n "`cat /proc/acpi/wakeup | grep PS2K | grep enabled`" ]
then    
#strange wakeups prevention
    for num in 1 2 3 4 7; do echo "USB$num" >> /proc/acpi/wakeup; done;
    echo 'PS2K' >> /proc/acpi/wakeup;
fi;