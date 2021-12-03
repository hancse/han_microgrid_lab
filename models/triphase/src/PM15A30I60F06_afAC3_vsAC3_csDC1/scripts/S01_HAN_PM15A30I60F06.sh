#!/bin/bash

SLAVE_OFFSET=0

echo "CONFIGURING POWER MODULE: PM15A30I60F06"
PREFIX="avhb_10006367"

## Configure Inverter KEB_1 ##
let SLAVE=0
set -e
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
# KEB_1 Drive Measurements and Limits (KEB 16F5C1G-360A)
mz1_m4 $AVHB_DEV start "0, 1, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "1, 2, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "2, 3, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "3, 0, 0xffff0000, 0x3fed0000, 0.061035000, V"
ds_lim $AVHB_DEV "0, 0.061035000, -20, 800"
ds_lim $AVHB_DEV "1, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "2, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "3, 0.005493164, -60, 60"
# KEB_1 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "4, 5, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "5, 6, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "6, 7, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "7, 4, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "4, 0.003125, -150, 150"
ds_lim $AVHB_DEV "5, 0.003125, -150, 150"
ds_lim $AVHB_DEV "6, 0.003125, -150, 150"
ds_lim $AVHB_DEV "7, 0.003125, -150, 150"
# KEB_1 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
mz2_m1 $AVHB_DEV start "0, 0+8, 8"
mz2_m1 $AVHB_DEV start "1, 1+8, 9"
mz2_m1 $AVHB_DEV start "2, 2+8, 10"
mz2_m1 $AVHB_DEV start "3, 3+8, 11"
mz2_m1 $AVHB_DEV start "4, 4+8, 12"
mz2_m1 $AVHB_DEV start "5, 5+8, 13"
ds_lim $AVHB_DEV "8, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "9, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "10, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "11, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "12, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "13, 0.091552734, -1500, 1500"

## Configure Inverter FC3 transformer

## Configure Interposer FC3 ##
let SLAVE=1
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring FC3 AVHB slave $SLAVE ($AVHB_DEV)  Transformer box"
# KEB_3 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
mz2_m1 $AVHB_DEV start "0, 0+4, 0"
mz2_m1 $AVHB_DEV start "1, 1+4, 1"
mz2_m1 $AVHB_DEV start "2, 2+4, 2"
#mz2_m1 $AVHB_DEV start "3, 3+4, 3"
#mz2_m1 $AVHB_DEV start "4, 4+4, 4"
#mz2_m1 $AVHB_DEV start "5, 5+4, 5"
#mz2_m1 $AVHB_DEV start "6, 6+4, 6"
#mz2_m1 $AVHB_DEV start "7, 7+4, 7"
ds_lim $AVHB_DEV "0, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "1, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "2, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "3, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "4, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "5, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "6, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "7, 0.091552734, -1500, 1500"
# KEB_3 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "0, 8, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "1, 9, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "2, 10, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "3, 11, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "8, 0.003125, -150, 150"
ds_lim $AVHB_DEV "9, 0.003125, -150, 150"
ds_lim $AVHB_DEV "10, 0.003125, -150, 150"
ds_lim $AVHB_DEV "11, 0.003125, -150, 150"
# disablen van de limieten van de kanalen die niet in gebruik zijn.
ds_dis $AVHB_DEV "3"
ds_dis $AVHB_DEV "4"
ds_dis $AVHB_DEV "5"
ds_dis $AVHB_DEV "6"
ds_dis $AVHB_DEV "7"
#in commentaar want deze zijn in gebruik
#ds_dis $AVHB_DEV "8"
#ds_dis $AVHB_DEV "9"
#ds_dis $AVHB_DEV "10"
#ds_dis $AVHB_DEV "11"
ds_dis $AVHB_DEV "12"
ds_dis $AVHB_DEV "13"
ds_dis $AVHB_DEV "14"
ds_dis $AVHB_DEV "15"
#FC3 heeft van 0-15 kanalen, niet boven kanaal 16 disablen.


## Configure Inverter KEB_2 ##
let SLAVE=2
set -e
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
# KEB_1 Drive Measurements and Limits (KEB 16F5C1G-360A)
mz1_m4 $AVHB_DEV start "0, 1, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "1, 2, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "2, 3, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "3, 0, 0xffff0000, 0x3fed0000, 0.061035000, V"
ds_lim $AVHB_DEV "0, 0.061035000, -20, 800"
ds_lim $AVHB_DEV "1, 0.005493164, -70, 70"
ds_lim $AVHB_DEV "2, 0.005493164, -70, 70"
ds_lim $AVHB_DEV "3, 0.005493164, -70, 70"
# KEB_1 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "4, 5, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "5, 6, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "6, 7, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "7, 4, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "4, 0.003125, -150, 150"
ds_lim $AVHB_DEV "5, 0.003125, -150, 150"
ds_lim $AVHB_DEV "6, 0.003125, -150, 150"
ds_lim $AVHB_DEV "7, 0.003125, -150, 150"
# KEB_1 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
#mz2_m1 $AVHB_DEV start "0, 0+8, 8"
#mz2_m1 $AVHB_DEV start "1, 1+8, 9"
#mz2_m1 $AVHB_DEV start "2, 2+8, 10"
mz2_m1 $AVHB_DEV start "3, 3+8, 11"
mz2_m1 $AVHB_DEV start "4, 4+8, 12"
mz2_m1 $AVHB_DEV start "5, 5+8, 13"
#ds_lim $AVHB_DEV "8, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "9, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "10, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "11, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "12, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "13, 0.091552734, -1500, 1500"
ds_dis $AVHB_DEV "8"
ds_dis $AVHB_DEV "9" 
ds_dis $AVHB_DEV "10"


## Configure Inverter FC3 transformer

## Configure Interposer FC3 ##
let SLAVE=3
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring FC3 AVHB slave $SLAVE ($AVHB_DEV)  Transformer box"
# KEB_3 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
mz2_m1 $AVHB_DEV start "0, 0+4, 0"
mz2_m1 $AVHB_DEV start "1, 1+4, 1"
mz2_m1 $AVHB_DEV start "2, 2+4, 2"
#mz2_m1 $AVHB_DEV start "3, 3+4, 3"
#mz2_m1 $AVHB_DEV start "4, 4+4, 4"
#mz2_m1 $AVHB_DEV start "5, 5+4, 5"
#mz2_m1 $AVHB_DEV start "6, 6+4, 6"
#mz2_m1 $AVHB_DEV start "7, 7+4, 7"
ds_lim $AVHB_DEV "0, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "1, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "2, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "3, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "4, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "5, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "6, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "7, 0.091552734, -1500, 1500"
# KEB_3 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "0, 8, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "1, 9, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "2, 10, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "3, 11, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "8, 0.003125, -150, 150"
ds_lim $AVHB_DEV "9, 0.003125, -150, 150"
ds_lim $AVHB_DEV "10, 0.003125, -150, 150"
ds_lim $AVHB_DEV "11, 0.003125, -150, 150"
# disablen van de limieten van de kanalen die niet in gebruik zijn.
ds_dis $AVHB_DEV "3"
ds_dis $AVHB_DEV "4"
ds_dis $AVHB_DEV "5"
ds_dis $AVHB_DEV "6"

ds_dis $AVHB_DEV "7"
#in commentaar want deze zijn in gebruik
#ds_dis $AVHB_DEV "8"
#ds_dis $AVHB_DEV "9"
#ds_dis $AVHB_DEV "10"
#ds_dis $AVHB_DEV "11"
ds_dis $AVHB_DEV "12"
ds_dis $AVHB_DEV "13"
ds_dis $AVHB_DEV "14"
ds_dis $AVHB_DEV "15"
#FC3 heeft van 0-15 kanalen, niet boven kanaal 16 disablen.

## Configure Inverter KEB_3 ##
let SLAVE=4
set -e
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
# KEB_1 Drive Measurements and Limits (KEB 16F5C1G-360A)
mz1_m4 $AVHB_DEV start "0, 1, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "1, 2, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "2, 3, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "3, 0, 0xffff0000, 0x3fed0000, 0.061035000, V"
ds_lim $AVHB_DEV "0, 0.061035000, -20, 800"
ds_lim $AVHB_DEV "1, 0.005493164, -70, 70"
ds_lim $AVHB_DEV "2, 0.005493164, -70, 70"
ds_lim $AVHB_DEV "3, 0.005493164, -70, 70"
# KEB_1 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "4, 5, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "5, 6, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "6, 7, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "7, 4, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "4, 0.003125, -150, 150"
ds_lim $AVHB_DEV "5, 0.003125, -150, 150"
ds_lim $AVHB_DEV "6, 0.003125, -150, 150"
ds_lim $AVHB_DEV "7, 0.003125, -150, 150"
# KEB_1 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
#mz2_m1 $AVHB_DEV start "0, 0+8, 8"
#mz2_m1 $AVHB_DEV start "1, 1+8, 9"
#mz2_m1 $AVHB_DEV start "2, 2+8, 10"
mz2_m1 $AVHB_DEV start "3, 3+8, 11"
mz2_m1 $AVHB_DEV start "4, 4+8, 12"
mz2_m1 $AVHB_DEV start "5, 5+8, 13"
#ds_lim $AVHB_DEV "8, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "9, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "10, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "11, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "12, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "13, 0.091552734, -1500, 1500"

ds_dis $AVHB_DEV "8"
ds_dis $AVHB_DEV "9"
ds_dis $AVHB_DEV "10"



## Configure Inverter KEB_4 ##
let SLAVE=5
set -e
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
# KEB_1 Drive Measurements and Limits (KEB 16F5C1G-360A)
mz1_m4 $AVHB_DEV start "0, 1, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "1, 2, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "2, 3, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "3, 0, 0xffff0000, 0x3fed0000, 0.061035000, V"
ds_lim $AVHB_DEV "0, 0.061035000, -20, 800"
ds_lim $AVHB_DEV "1, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "2, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "3, 0.005493164, -60, 60"
# KEB_1 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "4, 5, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "5, 6, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "6, 7, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "7, 4, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "4, 0.003125, -150, 150"
ds_lim $AVHB_DEV "5, 0.003125, -150, 150"
ds_lim $AVHB_DEV "6, 0.003125, -150, 150"
ds_lim $AVHB_DEV "7, 0.003125, -150, 150"
# KEB_1 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
mz2_m1 $AVHB_DEV start "0, 0+8, 8"
mz2_m1 $AVHB_DEV start "1, 1+8, 9"
mz2_m1 $AVHB_DEV start "2, 2+8, 10"
mz2_m1 $AVHB_DEV start "3, 3+8, 11"
mz2_m1 $AVHB_DEV start "4, 4+8, 12"
mz2_m1 $AVHB_DEV start "5, 5+8, 13"
ds_lim $AVHB_DEV "8, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "9, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "10, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "11, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "12, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "13, 0.091552734, -1500, 1500"

## Configure Inverter KEB_5 ##
let SLAVE=6
set -e
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
# KEB_1 Drive Measurements and Limits (KEB 16F5C1G-360A)
mz1_m4 $AVHB_DEV start "0, 1, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "1, 2, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "2, 3, 0xc0000000, 0x40000000, 0.005493164, A"
mz1_m4 $AVHB_DEV start "3, 0, 0xffff0000, 0x3fed0000, 0.061035000, V"
ds_lim $AVHB_DEV "0, 0.061035000, -20, 800"
ds_lim $AVHB_DEV "1, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "2, 0.005493164, -60, 60"
ds_lim $AVHB_DEV "3, 0.005493164, -60, 60"
# KEB_1 Meas 4 Measurements and Limits (LEM LA-55-P)
mz1_m4 $AVHB_DEV start "4, 5, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "5, 6, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "6, 7, 0xc0000000, 0x40000000, 0.003125, A"
mz1_m4 $AVHB_DEV start "7, 4, 0xc0000000, 0x40000000, 0.003125, A"
ds_lim $AVHB_DEV "4, 0.003125, -150, 150"
ds_lim $AVHB_DEV "5, 0.003125, -150, 150"
ds_lim $AVHB_DEV "6, 0.003125, -150, 150"
ds_lim $AVHB_DEV "7, 0.003125, -150, 150"
# KEB_1 MZ2 Voltage Measurements and Limits (3P VOLT_MEAS_DI)
mz2_m1 $AVHB_DEV start "0, 0+8, 8"
mz2_m1 $AVHB_DEV start "1, 1+8, 9"
mz2_m1 $AVHB_DEV start "2, 2+8, 10"

echo " mz2_m1 $AVHB_DEV start 3, 3+8, 11"
mz2_m1 $AVHB_DEV start "3, 3+8, 11"
mz2_m1 $AVHB_DEV start "4, 4+8, 12"
mz2_m1 $AVHB_DEV start "5, 5+8, 13"
ds_lim $AVHB_DEV "8, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "9, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "10, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "11, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "12, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "13, 0.091552734, -1500, 1500"
