module mod_cli_sea
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public fmask_s, bmask_s, deglat_s, sst12, sice12, sstan3, hfseacl, sstom12

    ! Sea masks
    ! Fraction of sea
    type(rpe_var) :: fmask_s(ix,il)

    ! Binary sea mask
    type(rpe_var) :: bmask_s(ix,il)

    ! Grid latitudes
    type(rpe_var) :: deglat_s(il)

    ! Monthly-mean climatological fields over sea
    ! Sea/ice surface temperature
    type(rpe_var) :: sst12(ix,il,12)

    ! Sea ice fraction
    type(rpe_var) :: sice12(ix,il,12)

    ! SST anomaly fields
    ! SST anomaly in 3 consecutive months
    type(rpe_var) :: sstan3(ix,il,3)

    ! Climatological fields from model output
    ! Annual-mean heat flux into sea sfc.
    type(rpe_var) :: hfseacl(ix,il)

    ! Ocean model SST climatology
    type(rpe_var) :: sstom12(ix,il,12)
end module
