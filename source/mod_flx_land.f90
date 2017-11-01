module mod_flx_land
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public prec_l, snowf_l, evap_l, ustr_l, vstr_l, ssr_l, slr_l, shf_l, ehf_l,&
        & hflux_l

    ! Fluxes at land surface (all downward, except evaporation)
    ! Precipitation (land)
    type(rpe_var) :: prec_l(ix*il)

    ! Snowfall (land)
    type(rpe_var) :: snowf_l(ix*il)

    ! Evaporation (land)
    type(rpe_var) :: evap_l(ix*il)

    ! u-wind stress (land)
    type(rpe_var) :: ustr_l(ix*il)

    ! v-wind stress (land)
    type(rpe_var) :: vstr_l(ix*il)

    ! Sfc short-wave radiation (land)
    type(rpe_var) :: ssr_l(ix*il)

    ! Sfc long-wave radiation (land)
    type(rpe_var) :: slr_l(ix*il)

    ! Sensible heat flux (land)
    type(rpe_var) :: shf_l(ix*il)

    ! Latent heat flux (land)
    type(rpe_var) :: ehf_l(ix*il)

    ! Net heat flux into land sfc.end module
    type(rpe_var) :: hflux_l(ix*il)
end module
