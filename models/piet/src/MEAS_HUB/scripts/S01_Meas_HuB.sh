#!/bin/bash


PREFIX="avhb_10006363"

## Configure Interposer FC3 ##
let SLAVE=0
AVHB_DEV="/dev/"$PREFIX"_$SLAVE"

echo "Configuring AVHB slave $SLAVE ($AVHB_DEV)"
echo "#########################################"
mz2_m1 $AVHB_DEV start "0, 0+4, 0"
mz2_m1 $AVHB_DEV start "1, 1+4, 1"
mz2_m1 $AVHB_DEV start "2, 2+4, 2"
#mz2_m1 $AVHB_DEV start "3, 3+4, 3"
#mz2_m1 $AVHB_DEV start "4, 4+4, 4"
#mz2_m1 $AVHB_DEV start "5, 5+4, 5"
ds_lim $AVHB_DEV "0, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "1, 0.091552734, -1500, 1500"
ds_lim $AVHB_DEV "2, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "3, 0.091552734, -1500, 1500"
#ds_lim $AVHB_DEV "4, 0.091552734, -800, 800"
#ds_lim $AVHB_DEV "5, 0.091552734, -800, 800"
mz1_m4 $AVHB_DEV start "0, 8, 0x40000000, 0xc0000000, 0.0031433, A"
mz1_m4 $AVHB_DEV start "1, 9, 0x40000000, 0xc0000000, 0.0031433, A"
mz1_m4 $AVHB_DEV start "2, 10, 0x40000000, 0xc0000000, 0.0031433, A"
ds_lim $AVHB_DEV "8, 0.0031433, -40, 40"
ds_lim $AVHB_DEV "9, 0.0031433, -40, 40"
ds_lim $AVHB_DEV "10, 0.0031433, -40, 40"
ds_dis $AVHB_DEV "3"
ds_dis $AVHB_DEV "4"
ds_dis $AVHB_DEV "5"
ds_dis $AVHB_DEV "6"
ds_dis $AVHB_DEV "7"
ds_dis $AVHB_DEV "11"
ds_dis $AVHB_DEV "12"
ds_dis $AVHB_DEV "13"
ds_dis $AVHB_DEV "14"
ds_dis $AVHB_DEV "15"

