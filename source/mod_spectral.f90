module mod_spectral
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public el2, elm2, el4, trfilt, l2, ll, mm, nsh2, sia, coa, wt, wght, cosg,&
        & cosgr, cosgr2, gradx, gradym, gradyp, sqrhlf, consq, epsi, repsi,&
        & emm, ell, poly, cpol, uvdx, uvdym, uvdyp, vddym, vddyp

    ! Initial. in parmtr
    type(rpe_var), dimension(mx,nx) :: el2, elm2, el4, trfilt
    integer :: l2(mx,nx), ll(mx,nx), mm(mx), nsh2(nx)

    ! Initial. in parmtr
    type(rpe_var), dimension(iy) :: sia, coa, wt, wght
    type(rpe_var), dimension(il) :: cosg, cosgr, cosgr2

    ! Initial. in parmtr
    type(rpe_var) :: gradx(mx), gradym(mx,nx), gradyp(mx,nx)

    ! Initial. in parmtr
    type(rpe_var) :: sqrhlf, consq(mxp), epsi(mxp,nxp), repsi(mxp,nxp), emm(mxp), ell(mxp,nxp)

    ! Initial. in parmtr
    type(rpe_var) :: poly(mx,nx)

    ! Initial. in parmtr
    type(rpe_var) :: cpol(mx2,nx,iy)

    ! Initial. in parmtr
    type(rpe_var), dimension(mx,nx) :: uvdx, uvdym, uvdyp

    ! Initial. in parmtr
    type(rpe_var), dimension(mx,nx) :: vddym, vddyp
end module
