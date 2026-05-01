#!/bin/bash
# Turns off the front LEDs on R35S (Clone R36S Soy Sauce).
# The panel driver (simple-panel-dsi / HX8394F) asserts GPIO0_A0 (blue LED)
# and GPIO0_A5 (red LED) HIGH during display init and never clears them.
# This script drives them LOW after boot.
#
# RK3326 GPIO sysfs numbers:
#   GPIO0_A0 = 0  (blue front LED, led-blue1-gpios in DTB panel node)
#   GPIO0_A5 = 5  (red front LED,  led-red-gpios  in DTB panel node)

for gpio in 0 5; do
    if [ ! -d /sys/class/gpio/gpio${gpio} ]; then
        echo $gpio > /sys/class/gpio/export
        sleep 0.05
    fi
    echo out  > /sys/class/gpio/gpio${gpio}/direction
    echo 0    > /sys/class/gpio/gpio${gpio}/value
done
