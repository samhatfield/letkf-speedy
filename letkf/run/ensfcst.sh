#!/bin/bash
#=======================================================================
# ensfcst.sh
#   This script runs the SPEEDY model with subdirectory $PROC
#=======================================================================

# Input for this shell
SPEEDY=$1
OUTPUT=$2
YMDH=$3
TYMDH=$4
MEM=$5
PROC=$6

if test 5$6 -eq 5
then
    echo "ERROR in ensfcst.sh"
    exit
fi

# Create directory for this process
rm -rf $PROC
mkdir $PROC
cp imp.exe $PROC

# Set up boundary files
SB=$SPEEDY/model/data/bc/t30/clim
SC=$SPEEDY/model/data/bc/t30/anom
ln -s $SB/sfc.grd   $PROC/fort.20
ln -s $SB/sst.grd   $PROC/fort.21
ln -s $SB/icec.grd  $PROC/fort.22
ln -s $SB/stl.grd   $PROC/fort.23	
ln -s $SB/snowd.grd $PROC/fort.24
ln -s $SB/swet.grd  $PROC/fort.26
cp    $SC/ssta.grd  $PROC/fort.30	

# Run
cd $PROC
ln -fs $OUTPUT/anal/$MEM/$YMDH.grd fort.90
ln -fs $OUTPUT/gues/$MEM/fluxes.grd fluxes.grd
FORT2=2
echo $FORT2 > fort.2
echo $YMDH | cut -c1-4 >> fort.2
echo $YMDH | cut -c5-6 >> fort.2
echo $YMDH | cut -c7-8 >> fort.2
echo $YMDH | cut -c9-10 >> fort.2
./imp.exe > out.lis 2> out.lis.2

# Move output
mv ${YMDH}.grd $OUTPUT/anal_f/$MEM
mv ${TYMDH}.grd $OUTPUT/gues/$MEM
exit 0
