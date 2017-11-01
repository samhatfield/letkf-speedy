module mod_flx_sea
    use mod_atparam
	use rp_emulator

    implicit none

    private
    public prec_s, snowf_s, evap_s, ustr_s, vstr_s, ssr_s, slr_s, shf_s, ehf_s,&
        & hflux_s, hflux_i

    ! Fluxes at sea surface (all downward, except evaporation)
    ! Precipitation (sea)
    type(rpe_var) :: prec_s(ix*il)
    
    ! Snowfall (sea)
    type(rpe_var) :: snowf_s(ix*il)

    ! Evaporation (sea)
    type(rpe_var) :: evap_s(ix*il)

    ! u-wind stress (sea)
    type(rpe_var) :: ustr_s(ix*il)

    ! v-wind stress (sea)
    type(rpe_var) :: vstr_s(ix*il)

    ! Sfc short-wave radiation (sea)
    type(rpe_var) :: ssr_s(ix*il)

    ! Sfc long-wave radiation (sea)
    type(rpe_var) :: slr_s(ix*il)

    ! Sensible heat flux (sea)
    type(rpe_var) :: shf_s(ix*il)

    ! Latent heat flux (sea)
    type(rpe_var) :: ehf_s(ix*il)

    ! Net heat flux into sea sfc.
    type(rpe_var) :: hflux_s(ix*il)

    ! Net heat flux into sea-ice sfc.
    type(rpe_var) :: hflux_i(ix*il)
end module
