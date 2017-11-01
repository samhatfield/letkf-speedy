module mod_var_sea
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public sstcl_ob, sicecl_ob, ticecl_ob, sstan_ob, sstcl_om, sst_am, sstan_am
    public sice_am, tice_am, sst_om, sice_om, tice_om, ssti_om, wsst_ob

    ! Daily observed climatological fields over sea
    ! Observed clim. SST
    type(rpe_var) :: sstcl_ob(ix*il)

    ! Clim. sea ice fraction
    type(rpe_var) :: sicecl_ob(ix*il)

    ! Clim. sea ice temperature
    type(rpe_var) :: ticecl_ob(ix*il)

    ! Daily observed SST anomaly
    ! Observed SST anomaly
    type(rpe_var) :: sstan_ob(ix*il)

    ! Daily climatological fields from ocean model
    ! Ocean model clim. SST
    type(rpe_var) :: sstcl_om(ix*il)

    ! Sea sfc. fields used by atmospheric model
    ! SST (full-field)
    type(rpe_var) :: sst_am(ix*il)

    ! SST anomaly
    type(rpe_var) :: sstan_am(ix*il)

    ! Sea ice fraction
    type(rpe_var) :: sice_am(ix*il)

    ! Sea ice temperature
    type(rpe_var) :: tice_am(ix*il)

    ! Sea sfc. fields from ocean/sea-ice model
    ! Ocean model SST
    type(rpe_var) :: sst_om(ix*il)

    ! Model sea ice fraction
    type(rpe_var) :: sice_om(ix*il)

    ! Model sea ice temperature
    type(rpe_var) :: tice_om(ix*il)

    ! Model SST + sea ice temp.
    type(rpe_var) :: ssti_om(ix*il)

    ! Weight for obs. SST anomaly in coupled runs
    ! Weight mask for obs. SST
    type(rpe_var) :: wsst_ob(ix*il)
end module
