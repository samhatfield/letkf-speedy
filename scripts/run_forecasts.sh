#!/bin/sh
#=======================================================================
# run_forecasts.sh
#   To run medium range forecasts from SPEEDY/LETKF analyses.
#=======================================================================

if [ $# -lt 1 ]; then
    echo "bash process.sh PRECISION"
    exit 1
fi

# Directory settings
cd ..
SPEEDY=`pwd`

# Source experiment configuration and time increment function
source $SPEEDY/config.sh
source $SPEEDY/common/timeinc.sh

# Define assimilation output, forecast output and temporary directories
ASSIM_OUTPUT=$SPEEDY/DATA/ensemble/anal/mean
OUTPUT=$SPEEDY/DATA/forecasts
TMPDIR=$SPEEDY/DATA/tmp/forecasts 

# Actually make directories
rm -rf $OUTPUT
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR
mkdir -p $OUTPUT

# Define months array
MONTHS=(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC)

# Length of forecasts in days
LEN_DAYS=15

# Length of forecasts in number of assimilation cycles
LEN=`expr $LEN_DAYS \* 24 / 6`

echo "Running $LEN_DAYS day forecasts"

echo 'Building model'

# Choose precision
if [[ "$1" = "double" ]]
then
    # Double precision SPEEDY
    cp $SPEEDY/model/source/makefile .
    cp $SPEEDY/model/source/*.h .
    cp $SPEEDY/model/source/*.f90 .
    cp $SPEEDY/model/source/*.s .
elif [[ "$1" = "reduced" ]]
then
    # Reduced precision SPEEDY
    cp $SPEEDY/model_rp/source/makefile .
    cp $SPEEDY/model_rp/source/*.h .
    cp $SPEEDY/model_rp/source/*.f90 .
    cp $SPEEDY/model_rp/source/*.s .
    cp -r $SPEEDY/model_rp/rpe/modules .
    cp -r $SPEEDY/model_rp/rpe/lib .
elif [[ "$1" = "mixed" ]]
then
    # Mixed precision SPEEDY
    cp $SPEEDY/model_mp/source/makefile .
    cp $SPEEDY/model_mp/source/*.h .
    cp $SPEEDY/model_mp/source/*.f90 .
    cp $SPEEDY/model_mp/source/*.s .
    cp -r $SPEEDY/model_mp/rpe/modules .
    cp -r $SPEEDY/model_mp/rpe/lib .
fi

# Set resolution
sed -i "s/NTRUN/30/g" mod_atparam.f90
sed -i "s/NLON/96/g" mod_atparam.f90
sed -i "s/NLAT/48/g" mod_atparam.f90
sed -i "s/NSTEPS/36/g" mod_tsteps.f90

sed -i "s/NMONTS/1/g" mod_tsteps.f90
sed -i "s/NMONRS/0/g" mod_tsteps.f90
sed -i "s/IHOUT/.true./g" mod_tsteps.f90
sed -i "s/IPOUT/.true./g" mod_tsteps.f90
sed -i "s/SIXHRRUN/.true./g" mod_tsteps.f90

make -s imp.exe

# Set up boundary files
SB=$SPEEDY/model/data/bc/t30/clim
SC=$SPEEDY/model/data/bc/t30/anom
ln -s $SB/sfc.grd   fort.20
ln -s $SB/sst.grd   fort.21
ln -s $SB/icec.grd  fort.22
ln -s $SB/stl.grd   fort.23	
ln -s $SB/snowd.grd fort.24
ln -s $SB/swet.grd  fort.26
cp    $SC/ssta.grd  fort.30	

# Get current time
T="$(date +%s)"

# Cycle run
YYYY=1982
MM=03
DD=01
HH=00
while test $YYYY$MM$DD$HH -le $FYYYY$FMM$FDD$FHH
do
    echo "Begin forecast from $YYYY/$MM/$DD/$HH"
    TY=`timeinc6hr $YYYY $MM $DD $HH | cut -c1-4`
    TM=`timeinc6hr $YYYY $MM $DD $HH | cut -c5-6`
    TD=`timeinc6hr $YYYY $MM $DD $HH | cut -c7-8`
    TH=`timeinc6hr $YYYY $MM $DD $HH | cut -c9-10`

    FY=$YYYY
    FM=$MM
    FD=$DD
    FH=$HH

    # Move to this directory and copy executable
    ln -fs $ASSIM_OUTPUT/$YYYY$MM$DD$HH.grd fort.90

    # Loop over forecast
    for i in $(seq 1 $LEN)
    do
        FORT2=2
        echo $FORT2 > fort.2
        echo $FY >> fort.2
        echo $FM >> fort.2
        echo $FD >> fort.2
        echo $FH >> fort.2
        ./imp.exe &> out.lis

        FY2=`timeinc6hr $FY $FM $FD $FH | cut -c1-4`
        FM2=`timeinc6hr $FY $FM $FD $FH | cut -c5-6`
        FD2=`timeinc6hr $FY $FM $FD $FH | cut -c7-8`
        FH2=`timeinc6hr $FY $FM $FD $FH | cut -c9-10`
        FY=$FY2
        FM=$FM2
        FD=$FD2
        FH=$FH2

        ln -fs $FY$FM$FD$FH.grd fort.90
    done

    # Convert to NetCDF
    cp $SPEEDY/common/t30.ctl .
    datestring=${HH}Z$DD${MONTHS[`expr $MM - 1`]}$YYYY
    sed -i "s/00Z01JAN1982/$datestring/g" t30.ctl
    ctl2nc t30.ctl
    mv t30.nc $OUTPUT/$YYYY$MM$DD$HH.nc

    ls *.grd | grep -v 'fluxes.grd' | xargs rm
    rm *.ctl

    # Date increment
    YYYY=$TY
    MM=$TM
    DD=$TD
    HH=$TH
done

# Get end time
T="$(($(date +%s)-T))"
echo "Took ${T} seconds"
