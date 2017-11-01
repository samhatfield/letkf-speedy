#!/bin/bash

# Directory settings
cd ..
SPEEDY=`pwd`
NATURE=$SPEEDY/DATA/nature
OBSDIR=$SPEEDY/DATA/obs

# Source experiment configuration and time increment function
source $SPEEDY/config.sh
source $SPEEDY/common/timeinc.sh

cd $SPEEDY/obs
mkdir -p $OBSDIR
ln -s $SPEEDY/common/orography_t30.dat fort.21

echo "Building obsmake"
make -f obsmake_Makefile
make -f obsmake_Makefile clean

echo "Setting up observation network"
cp networks/$obs_network.txt station.txt

echo "Setting obs error"
cat << EOF > obserr.tbl
F ELEM  OBER
F ----- ---------
T  2819  $u_err
T  2820  $v_err
T  3073  $t_err
T  3330  $q_err
T 14593  $ps_err
EOF

echo "Extracting observations"
YYYY=$IYYYY
MM=$IMM
DD=$IDD
HH=$IHH
while test $YYYY$MM$DD$HH -le $FYYYY$FMM$FDD$FHH
do
    echo "Extracting observations for $YYYY/$MM/$DD/$HH"

    # Link nature file for this time
    ln -s $NATURE/$YYYY$MM$DD$HH.grd true.grd
    
    # Extract observations
    ./obsmake &> /dev/null
    
    # Move observations to output directory
    mv obs.dat $OBSDIR/$YYYY$MM$DD$HH.dat
    rm true.grd
    
    # Increment timer by 6 hours
    TY=`timeinc6hr $YYYY $MM $DD $HH | cut -c1-4`
    TM=`timeinc6hr $YYYY $MM $DD $HH | cut -c5-6`
    TD=`timeinc6hr $YYYY $MM $DD $HH | cut -c7-8`
    TH=`timeinc6hr $YYYY $MM $DD $HH | cut -c9-10`
    YYYY=$TY
    MM=$TM
    DD=$TD
    HH=$TH
done

echo "Cleaning up"
rm fort.21
rm station.txt
rm obserr.tbl
