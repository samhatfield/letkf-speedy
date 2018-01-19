module mod_spectral
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public el2, elm2, el4, trfilt, l2, ll, mm, nsh2, sia, coa, wt, wght, cosg,&
        & cosgr, cosgr2, gradx, gradym, gradyp, sqrhlf, consq, epsi, repsi,&
        & emm, ell, poly, cpol, uvdx, uvdym, uvdyp, vddym, vddyp
    public get_scale_fact, truncate_spectral

    ! Initial. in parmtr
    real, dimension(mx,nx) :: el2, elm2, el4, trfilt
    integer :: l2(mx,nx), ll(mx,nx), mm(mx), nsh2(nx)

    ! Initial. in parmtr
    type(rpe_var), dimension(iy) :: wt
    real, dimension(iy) :: sia, coa, wght
    type(rpe_var), dimension(il) :: cosgr
    real, dimension(il) :: cosg, cosgr2

    ! Initial. in parmtr
    real :: gradx(mx), gradym(mx,nx), gradyp(mx,nx)

    ! Initial. in parmtr
    real :: sqrhlf, consq(mxp), epsi(mxp,nxp), repsi(mxp,nxp), emm(mxp), ell(mxp,nxp)

    ! Initial. in parmtr
    real :: poly(mx,nx)

    ! Initial. in parmtr
    type(rpe_var) :: cpol(mx2,nx,iy)

    ! Initial. in parmtr
    real, dimension(mx,nx) :: uvdx, uvdym, uvdyp

    ! Initial. in parmtr
    real, dimension(mx,nx) :: vddym, vddyp

    contains
        function get_scale_fact(input) result(scale_fact)
            real, intent(in) :: input(:,:)
            real, parameter :: threshold = 500.0, min_half = 2.0**(-14.0)
            real :: min_val, max_val
            real :: scale_fact

            scale_fact = 1.0

            min_val = minval(abs(input), input /= 0.0)
            if (min_val < min_half) then
                scale_fact = min_half/min_val
            end if
        
            max_val = maxval(abs(input*scale_fact))
            if (max_val > threshold) then
                scale_fact = scale_fact * threshold/max_val
            end if
        end

        subroutine truncate_spectral
            wt = wt
            cosgr = cosgr
            cpol = cpol
        end subroutine
end module
