#!/bin/bash

# Directory settings
cd ..
SPEEDY=`pwd`
NATURE_T39=$SPEEDY/DATA/nature_t39
NATURE_T30=$SPEEDY/DATA/nature_interp

# Source experiment configuration and time increment function
source $SPEEDY/config.sh
source $SPEEDY/common/timeinc.sh

# Make 
cd interpolate
make -f interpolate_Makefile

# Start
mkdir -p $NATURE_T30
mv $SPEEDY/DATA/nature $NATURE_T39

# Main loop
YYYY=$IYYYY
MM=$IMM
DD=$IDD
HH=$IHH
while test $YYYY$MM$DD$HH -le $FYYYY$FMM$FDD$FHH
do
    echo "Interpolating $YYYY/$MM/$DD/$HH"
    ln -s $NATURE_T39/$YYYY$MM$DD$HH.grd true.grd
    
    ./interpolate

    mv out.grd $NATURE_T30/$YYYY$MM$DD$HH.grd
    rm true.grd
    
    TY=`timeinc6hr $YYYY $MM $DD $HH | cut -c1-4`
    TM=`timeinc6hr $YYYY $MM $DD $HH | cut -c5-6`
    TD=`timeinc6hr $YYYY $MM $DD $HH | cut -c7-8`
    TH=`timeinc6hr $YYYY $MM $DD $HH | cut -c9-10`
    YYYY=$TY
    MM=$TM
    DD=$TD
    HH=$TH
done
