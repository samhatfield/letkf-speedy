#!/bin/bash

# Initial date
IYYYY=1982
IMM=01
IDD=01
IHH=00

# Final date
FYYYY=1983
FMM=03
FDD=01
FHH=00

# Number of ensemble members
n_ens=20

# Number of MPI processes to use
n_procs=4

# Nature run resolution (choose t30 or t39)
nat_res=t30

# Use perturbed parameters for model or not
pert=0

# Save all members or not (if it's 0 then only the mean and spread are saved)
save_ens=0

# Choose observation network (choose "real" or "uniform")
obs_network=real

# Observation errors
u_err=1.00E+00
v_err=1.00E+00
t_err=1.00E+00
q_err=1.00E-03
ps_err=1.00E+02

# RTPP factor
rtpp=0.0d0

# Horizontal and vertical covariance localisation length scales (in metres and
# sigma coordinates, respectively)
hor_loc=1000.0d3
ver_loc=0.1d0

# Multiplicative covariance inflation factor (negative means use adaptive
# inflation
cov_infl=-1.01d0

# Additive inflation directory (set "0" if you don't want to use it)
addi_dir=0
