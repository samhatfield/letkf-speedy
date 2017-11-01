module mod_physcon
    use mod_atparam
    use rp_emulator
    use mod_prec

    implicit none

    private
    public p0, gg, rd, cp, alhc, alhs, sbc
    public sig, sigl, sigh, dsig, pout, grdsig, grdscp, wvi, slat, clat
    public init_physcon

    ! Physical constants
    ! Reference pressure
    real(dp), parameter :: p0_ = 1.e+5

    ! Gravity accel.
    real(dp), parameter :: gg_ = 9.81

    ! Gas constant for dry air
    real(dp), parameter :: rd_ = 287.

    ! Specific heat at constant pressure
    real(dp), parameter :: cp_ = 1004.

    ! Latent heat of condensation, in J/g for consistency with spec.hum. in g/Kg
    real(dp), parameter :: alhc_ = 2501.0

    ! Latent heat of sublimation
    real(dp), parameter :: alhs_ = 2801.0

    ! Stefan-Boltzmann constant
    real(dp), parameter :: sbc_ = 5.67e-8

    !   Functions of sigma and latitude (initial. in INPHYS)
    !    sig    = full-level sigma 
    !    sigl   = logarithm of full-level sigma
    !    sigh   = half-level sigma
    !    dsig   = layer depth in sigma
    !    pout   = norm. pressure level [p/p0] for post-processing
    !    grdsig = g/(d_sigma p0) : to convert fluxes of u,v,q into d(u,v,q)/dt
    !    grdscp = g/(d_sigma p0 c_p): to convert energy fluxes into dT/dt
    !    wvi    = weights for vertical interpolation
    !    slat   = sin(lat)
    !    clat   = cos(lat)
    type(rpe_var), dimension(kx) :: sig, sigl, dsig, pout, grdsig, grdscp
    type(rpe_var) :: wvi(kx,2), sigh(0:kx)
    type(rpe_var), dimension(il) :: slat, clat

    ! Reduced precision versions
    type(rpe_var) :: p0
    type(rpe_var) :: gg
    type(rpe_var) :: rd
    type(rpe_var) :: cp
    type(rpe_var) :: alhc
    type(rpe_var) :: alhs
    type(rpe_var) :: sbc

    contains
        subroutine init_physcon
            p0 = p0_
            gg = gg_
            rd = rd_
            cp = cp_
            alhc = alhc_
            alhs = alhs_
            sbc = sbc_
        end subroutine
end module
