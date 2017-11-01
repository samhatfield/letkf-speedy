module mod_dyncon2
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public :: tref, tref1, tref2, tref3
    public :: xa, xb, xc, xd, xe, xf, xg, xh, xj, dhsx, elz

    ! Temp. profile for semi-imp. scheme (initial. in IMPINT)
    type(rpe_var), dimension(kx) :: tref, tref1, tref2, tref3

    type(rpe_var), dimension(kx,kx) :: xa, xb, xc, xd, xe
    type(rpe_var), dimension(kx,kx,lmax) :: xf, xg, xh, xj
    type(rpe_var) :: dhsx(kx), elz(mx,nx)                               
end module
