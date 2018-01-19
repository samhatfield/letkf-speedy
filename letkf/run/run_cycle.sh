#!/bin/bash
#=======================================================================
# letkf_cycle.sh
#   To run the SPEEDY-LETKF cycle in parallel computing environment
#=======================================================================
set -e

# Directory settings
cd ../..
SPEEDY=`pwd`

# Source experiment configuration and time increment function
source $SPEEDY/config.sh
source $SPEEDY/common/timeinc.sh

# Define output, observation, temporary and additive inflation directories
OUTPUT=$SPEEDY/DATA/ensemble
OBSDIR=$SPEEDY/DATA/obs
TMPDIR=$SPEEDY/DATA/tmp/letkf
ADDDIR=$SPEEDY/DATA/diff

# Work directory
rm -rf $TMPDIR
mkdir -p $TMPDIR/ensfcst
cd $TMPDIR/ensfcst
cp $SPEEDY/letkf/run/ensfcst.sh .

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

# Perturb parameters
if [[ $pert -eq "1" ]]
then
    echo "Perturbing parameters"
    mv mod_cnvcon.pert.f90 mod_cnvcon.f90
    mv mod_dyncon0.pert.f90 mod_dyncon0.f90
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

# Get current time
T="$(date +%s)"

# Cycle run 
YYYY=$IYYYY
MM=$IMM
DD=$IDD
HH=$IHH
while test $YYYY$MM$DD$HH -le $FYYYY$FMM$FDD$FHH
do
    echo "Assimilating observations for $YYYY/$MM/$DD/$HH"
    TY=`timeinc6hr $YYYY $MM $DD $HH | cut -c1-4`
    TM=`timeinc6hr $YYYY $MM $DD $HH | cut -c5-6`
    TD=`timeinc6hr $YYYY $MM $DD $HH | cut -c7-8`
    TH=`timeinc6hr $YYYY $MM $DD $HH | cut -c9-10`

    echo "Running LETKF"
    rm -rf $TMPDIR/letkf
    mkdir -p $TMPDIR/letkf
    cd $TMPDIR/letkf
    ln -s $SPEEDY/letkf/letkf letkf
    ln -s $SPEEDY/letkf/obsope obsope

    # Inputs
    ln -s $SPEEDY/common/orography_t30.dat fort.21
    ln -s $OBSDIR/$YYYY$MM$DD$HH.dat obsin.dat

    # Observe each ensemble member
    for MEM in $(seq -f "%03g" 1 $n_ens)
    do
        ln -s $OUTPUT/gues/$MEM/$YYYY$MM$DD$HH.grd gs01$MEM.grd
        ln -fs $OUTPUT/gues/$MEM/$YYYY$MM$DD$HH.grd gues.grd
        ./obsope > obsope.log
        mv obsout.dat obs01$MEM.dat
    done

    # Choose additive covariance inflation perturbations
    if [ $addi_dir -ne 0 ]
    then
        echo "Sampling additive noise archive"
        years=($(shuf -i 1982-2005))
        for MEM in `seq 1 $n_ens`
        do
            year=${years[$MEM-1]}
            ln -s $ADDDIR/$year$MM$DD$HH.grd adin$(printf %03d $MEM).grd
        done
    fi

    # If adaptive covariance inflation is being used, copy inflation .grd file
    if test -f $OUTPUT/infl_mul/$YYYY$MM$DD$HH.grd
    then
        ln -s $OUTPUT/infl_mul/$YYYY$MM$DD$HH.grd infl_mul.grd
    fi

    # Run actual LETKF program
    mpiexec -n $n_procs ./letkf < /dev/null > /dev/null
    tail -n 17 NOUT-000

    # Outputs
    mv NOUT-000 $OUTPUT/log/$YYYY$MM$DD$HH.log
    if test -f infl_mul.grd
    then
        cp infl_mul.grd $OUTPUT/infl_mul/$TY$TM$TD$TH.grd
    fi
    mv gues_me.grd $OUTPUT/gues/mean/$YYYY$MM$DD$HH.grd
    mv gues_sp.grd $OUTPUT/gues/sprd/$YYYY$MM$DD$HH.grd
    mv anal_me.grd $OUTPUT/anal/mean/$YYYY$MM$DD$HH.grd
    mv anal_sp.grd $OUTPUT/anal/sprd/$YYYY$MM$DD$HH.grd

    # Move analysis to output directory
    for MEM in $(seq -f "%03g" 1 $n_ens)
    do
        mv anal$MEM.grd $OUTPUT/anal/$MEM/$YYYY$MM$DD$HH.grd
    done

    echo "Running background ensemble forecast"
    cd $TMPDIR/ensfcst

    # For each member...
    for MEM in $(seq -f "%03g" 1 $n_ens)
    do
        # Get node number
        N=`printf "%02d" $(((10#$MEM-1) % n_procs + 1))`

        echo "Member $MEM in process $N"
        sh ensfcst.sh $SPEEDY $OUTPUT $YYYY$MM$DD$HH $TY$TM$TD$TH $MEM $N &

        ### wait for the end of parallel processing
        if test $N -eq $n_procs
        then
            time wait
        fi
    done
    
    # Clean up
    if test $save_ens -eq 0
    then
        for MEM in $(seq -f "%03g" 1 $n_ens)
        do
            rm -f $OUTPUT/gues/$MEM/$YYYY$MM$DD$HH.grd
            rm -f $OUTPUT/anal/$MEM/$YYYY$MM$DD$HH.grd
            rm -f $OUTPUT/anal_f/$MEM/$YYYY$MM$DD$HH.grd
        done
    fi

    # Date increment
    YYYY=$TY
    MM=$TM
    DD=$TD
    HH=$TH
done

# Get end time
T="$(($(date +%s)-T))"
echo "Took ${T} seconds"
