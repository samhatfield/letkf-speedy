#!/bin/bash
#=======================================================================
# run_first
#   To run the SPEEDY model for the first time. That is, you do not have
#   a gridded initial condition, so that the model starts from the
#   atmosphere at rest. The atmosphere at rest means zero winds
#   everywhere and constant T with vertical profile of the standard
#   atmosphere.
#=======================================================================

# Directory settings
cd ../..
SPEEDY=`pwd`
NATURE=$SPEEDY/DATA/nature
TMPDIR=$SPEEDY/model/tmp

# Source experiment configuration
source $SPEEDY/config.sh

echo "Creating output directory"
mkdir -p $NATURE
cp $SPEEDY/common/$nat_res.ctl $NATURE

# Work directory
echo "Creating work directory"
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

# 1-year spin-up
SYYYY=$((IYYYY-1))
SMM=$IMM
SDD=$IDD
SHH=$IHH

echo 'Building model'
cp $SPEEDY/model/source/makefile .
cp $SPEEDY/model/source/*.f90 .
cp $SPEEDY/model/source/*.h .
cp $SPEEDY/model/source/*.s .

echo "Patching configuration parameters"
if [[ "$nat_res" = "t39" ]]
then
    sed -i "s/NTRUN/39/g" mod_atparam.f90
    sed -i "s/NLON/120/g" mod_atparam.f90
    sed -i "s/NLAT/60/g" mod_atparam.f90
    sed -i "s/NSTEPS/72/g" mod_tsteps.f90
elif [[ "$nat_res" = "t30" ]]
then
    sed -i "s/NTRUN/30/g" mod_atparam.f90
    sed -i "s/NLON/96/g" mod_atparam.f90
    sed -i "s/NLAT/48/g" mod_atparam.f90
    sed -i "s/NSTEPS/36/g" mod_tsteps.f90
fi
sed -i "s/NMONTS/12/g" mod_tsteps.f90
sed -i "s/NMONRS/0/g" mod_tsteps.f90
sed -i "s/IHOUT/.true./g" mod_tsteps.f90
sed -i "s/IPOUT/.false./g" mod_tsteps.f90
sed -i "s/SIXHRRUN/.false./g" mod_tsteps.f90

make -s imp.exe

sh inpfiles.s $nat_res

echo "Begin spin-up from $IYYYY/$IMM/$IDD/$IHH"
FORT2=0
echo $FORT2 > fort.2
echo $SYYYY >> fort.2
echo $SMM >> fort.2
echo $SDD >> fort.2
echo $SHH >> fort.2
time ./imp.exe | tee out.lis

mv $IYYYY$IMM$IDD$IHH.grd $NATURE
 
echo "Cleaning up"
cd ..
rm -rf $TMPDIR
