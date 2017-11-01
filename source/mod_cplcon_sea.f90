module mod_cplcon_sea
    use mod_atparam
    use rp_emulator
    use mod_prec

    implicit none

    private
    public rhcaps, rhcapi, cdsea, cdice, beta

    ! Constant parameters and fields in sea/ice model
    ! 1./heat_capacity (sea)
    type(rpe_var) :: rhcaps(ix,il)

    ! 1./heat_capacity (ice)
    type(rpe_var) :: rhcapi(ix,il)

    ! 1./dissip_time (sea)
    type(rpe_var) :: cdsea(ix,il)

    ! 1./dissip_time (ice)
    type(rpe_var) :: cdice(ix,il)

    ! Heat flux coef. at sea/ice int.
    real(dp) :: beta = 1.0
end module
