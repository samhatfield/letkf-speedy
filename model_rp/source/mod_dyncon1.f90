module mod_dyncon1
    use mod_atparam
    use rp_emulator
    use mod_prec

    implicit none

    private
    public rearth, omega, grav, akap, rgas, pi, a, g
    public hsg, dhs, fsg, dhsr, fsgr
    public radang, gsin, gcos, coriol
    public xgeop1, xgeop2
    public init_dyncon1

    ! Physical constants for dynamics
    real(dp), parameter :: rearth_ = 6.371d+6
    real(dp), parameter :: omega_  = 7.292d-05
    real(dp), parameter :: grav_   = 9.81_dp
    real(dp), parameter :: akap_   = 2.0_dp/7.0_dp
    real(dp), parameter :: rgas_   = akap_*1004.0_dp
    real(dp), parameter :: pi_ = 4.0_dp*atan(1.0_dp)
    real(dp), parameter :: a_  = rearth_
    real(dp), parameter :: g_  = grav_

    ! Vertical level parameters (initial. in indyns)
    type(rpe_var) :: hsg(kxp), dhs(kx), fsg(kx), dhsr(kx), fsgr(kx)

    ! Functions of lat. and lon. (initial. in indyns)
    real(dp) :: radang(il), gsin(il), gcos(il), coriol(il)

    ! Constants for hydrostatic eq. (initial. in indyns)
    type(rpe_var) :: xgeop1(kx), xgeop2(kx)

    ! Reduced precision versions
    type(rpe_var) :: rearth
    type(rpe_var) :: omega
    type(rpe_var) :: grav
    type(rpe_var) :: akap
    type(rpe_var) :: rgas
    type(rpe_var) :: pi
    type(rpe_var) :: a
    type(rpe_var) :: g

    contains
        subroutine init_dyncon1
            rearth = rearth_
            omega = omega_
            grav = grav_
            akap = akap_
            rgas = rgas_
            pi = pi_
            a = a_
            g = g_
        end subroutine

end module
