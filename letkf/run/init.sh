#!/bin/bash
#=======================================================================
# init.sh
#   This script prepares for new LETKF cycle-run experiment
#=======================================================================
set -e

# Directory settings
cd ../..
SPEEDY=`pwd`

# Source experiment configuration and time increment function
source $SPEEDY/config.sh
source $SPEEDY/common/timeinc.sh

# Define nature, ensemble and LETKF directories
NATURE=$SPEEDY/DATA/nature
OUTPUT=$SPEEDY/DATA/ensemble
LETKF=$SPEEDY/letkf

echo "Deleting old output directory"
rm -rf $OUTPUT

echo "Making log and covariance inflation directories"
mkdir -p $OUTPUT/log
mkdir -p $OUTPUT/infl_mul

echo "Inserting experiment configuration parameters"
sed -i -r -e "s/n_ens = [0-9]+/n_ens = $n_ens/" $SPEEDY/common/common_letkf.f90
sed -i -r -e "s/relax_alpha = [0-9]+.[0-9]+d0/relax_alpha = $rtpp/" $SPEEDY/common/common_letkf.f90
sed -i -r -e "s/sigma_obs=[0-9]+.[0-9]+d[0-9]+/sigma_obs=$hor_loc/" $LETKF/letkf_obs.f90
sed -i -r -e "s/sigma_obsv=[0-9]+.[0-9]+d[0-9]+/sigma_obsv=$ver_loc/" $LETKF/letkf_obs.f90
sed -i -r -e "s/cov_infl_mul = -*[0-9]+.[0-9]+d0/cov_infl_mul = $cov_infl/" $LETKF/letkf_tools.f90
if [ $addi_dir -eq 0 ]
then
    sed -i -r -e "s/add_infl = (.true.|.false.)/add_infl = .false./" $LETKF/letkf.f90
else
    sed -i -r -e "s/add_infl = (.true.|.false.)/add_infl = .true./" $LETKF/letkf.f90
fi

echo "Making LETKF"
make -s -C $LETKF -f letkf_Makefile
make -s -C $LETKF -f letkf_Makefile clean
echo "Making observation operator"
make -s -C $LETKF -f obsope_Makefile
make -s -C $LETKF -f obsope_Makefile clean

echo "Copying CTL files to output directory"
sed -i -r -e "s/([0-9]{2}Z[0-9]{2}[A-Z]{3})[0-9]{4}/\1$IYYYY/" $SPEEDY/common/t30.ctl
cp $SPEEDY/common/t30.ctl $OUTPUT/infl_mul
for MEM in $(seq -f "%03g" 1 $n_ens)
do
    mkdir -p $OUTPUT/anal/$MEM
    mkdir -p $OUTPUT/anal_f/$MEM
    mkdir -p $OUTPUT/gues/$MEM
    cp $SPEEDY/common/t30.ctl $OUTPUT/anal/$MEM
    cp $SPEEDY/common/t30.ctl $OUTPUT/anal_f/$MEM
    cp $SPEEDY/common/t30.ctl $OUTPUT/gues/$MEM
    MEM=`expr $MEM + 1`
done

echo "Creating ensemble mean and spread directories"
for diagnostic in mean sprd
do
    mkdir -p $OUTPUT/anal/$diagnostic
    mkdir -p $OUTPUT/anal_f/$diagnostic
    mkdir -p $OUTPUT/gues/$diagnostic
    cp $SPEEDY/common/t30.ctl $OUTPUT/anal/$diagnostic
    cp $SPEEDY/common/t30.ctl $OUTPUT/anal_f/$diagnostic
    cp $SPEEDY/common/t30.ctl $OUTPUT/gues/$diagnostic
done

echo "Creating initial ensemble"
TY=$IYYYY
TM=02
TD=01
TH=00

for MEM in $(seq -f "%03g" 1 $n_ens)
do
    cp $NATURE/$TY$TM$TD$TH.grd $OUTPUT/gues/$MEM/$IYYYY$IMM$IDD$IHH.grd
    UY=`timeinc6hr $TY $TM $TD $TH | cut -c1-4`
    UM=`timeinc6hr $TY $TM $TD $TH | cut -c5-6`
    UD=`timeinc6hr $TY $TM $TD $TH | cut -c7-8`
    UH=`timeinc6hr $TY $TM $TD $TH | cut -c9-10`
    TY=`timeinc6hr $UY $UM $UD $UH | cut -c1-4`
    TM=`timeinc6hr $UY $UM $UD $UH | cut -c5-6`
    TD=`timeinc6hr $UY $UM $UD $UH | cut -c7-8`
    TH=`timeinc6hr $UY $UM $UD $UH | cut -c9-10`
    MEM=`expr $MEM + 1`
done
