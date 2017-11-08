#!/bin/bash

function grd2nc {
    echo "Processing $1"
    cdo -f nc import_binary $SPEEDY/DATA/$1/$3.ctl $SPEEDY/experiments/$exp_name/$2.nc
}

function fixmetadata {
    echo "Fixing NetCDF metadata for $1"
    ncatted -a standard_name,lev,c,c,atmosphere_sigma_coordinate $SPEEDY/experiments/$exp_name/$1.nc
    ncatted -a units,lev,d,c, $SPEEDY/experiments/$exp_name/$1.nc
}

SPEEDY=$(dirname `pwd`)

if [ $# -lt 2 ]; then
    echo "bash process.sh EXPERIMENT_NAME PRECISION"
    exit 1
fi

# Extract input arguments
exp_name=$1
prec=$2

# Create experiment directory
mkdir -p $SPEEDY/experiments/$exp_name/double
mkdir -p $SPEEDY/experiments/$exp_name/reduced

# Copy experiment config file
cp $SPEEDY/config.sh $SPEEDY/experiments/$exp_name

# Add git commit revision to config file
printf "\n# Git commit revision\n`git rev-parse HEAD`" >> $SPEEDY/experiments/$exp_name/config.sh

# If nature run hasn't been processed yet...
if [ ! -f $SPEEDY/experiments/$exp_name/nature.nc ]; then
    grd2nc nature nature t30
    fixmetadata nature
fi

# If there's a high resolution nature run, process this too
if [ -d "$SPEEDY/DATA/nature_t39" ]; then
    if [ ! -f $SPEEDY/experiments/$exp_name/nature_t39.nc ]; then
        grd2nc nature_t39 nature_t39 t39
        fixmetadata nature_t39
    fi
fi

# Process ensemble mean and spread
grd2nc ensemble/anal/mean $prec/mean t30
grd2nc ensemble/anal/sprd $prec/sprd t30

# Make the NetCDF file CF Conventions conforming
fixmetadata $prec/mean
fixmetadata $prec/sprd
