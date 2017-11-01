module mod_cli_land
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public fmask_l, bmask_l, stl12, snowd12, soilw12

    ! Land masks
    ! Fraction of land
    type(rpe_var) :: fmask_l(ix,il)

    ! Binary land mask
    type(rpe_var) :: bmask_l(ix,il)

    ! Monthly-mean climatological fields over land
    ! Land surface temperature
    type(rpe_var) :: stl12(ix,il,12)

    ! Snow depth (water equiv.)
    type(rpe_var) :: snowd12(ix,il,12)

    ! Soil water availabilityend module
    type(rpe_var) :: soilw12(ix,il,12)
end module
