!******************************************************************
subroutine gaussl_hr(x,w,m)
    !   a slightly modified version of a program in Numerical Recipes 
    !       (Cambridge Univ. Press, 1989)
    !   input:
    !      m    = number of gaussian latitudes between pole and equator
    !   output:
    !      x(m) = sin(gaussian latitude) 
    !      w(m) = weights in gaussian quadrature (sum should equal 1.0)

    implicit none

    real, intent(inout) :: x(m),w(m)
    integer, intent(in) :: m
    double precision :: z,z1,p1,p2,p3,pp
    double precision, parameter :: eps=3.d-14
    integer :: n, j, i

    n = 2*m

    z1 = 2.0

    do i=1,m
        z=cos(3.141592654d0*(i-.25d0)/(n+.5d0))
        do while (abs(z-z1).gt.eps)
            p1=1.d0
            p2=0.d0
    
            do j=1,n
              p3=p2
              p2=p1
              p1=((2.d0*j-1.d0)*z*p2-(j-1.d0)*p3)/j
            end do
    
            pp=n*(z*p1-p2)/(z*z-1.d0)
            z1=z
            z=z1-p1/pp
        end do

        x(i)=z
        w(i)=2.d0/((1.d0-z*z)*pp*pp)
    end do
end
!****************************************************************
subroutine parmtr_hr(a)
    use mod_atparam_hr
    use mod_spectral_hr

    implicit none

    !include "param1spec.h"

    real, intent(in) :: a
    real :: am1, am2, cosqr, el1, ell2, emm2

    integer :: j, jj, m, m1, m2, n

    ! initializes Legendre transforms and constants used for other
    ! subroutines that manipulate spherical harmonics
    !
    ! input:  A = radius of the sphere
    ! first compute Gaussian latitudes and weights at the IY points from 
    !     pole to equator
    ! SIA(IY) is sin of latitude, WT(IY) are Gaussian weights for quadratures,
    !   saved in mod_spectral
    call gaussl_hr(sia,wt,iy)
    am1 = 1./a
    am2=  1./(a*a)

    ! COA(IY) = cos(lat); WGHT needed for transforms, 
    !           saved in mod_spectral
    do j=1,iy
        cosqr = 1.0-sia(j)**2
        coa(j)=sqrt(cosqr)
        wght(j)=wt(j)/(a*cosqr)
    end do

    ! expand cosine and its reciprocal to cover both hemispheres, 
    !    saved in mod_spectral
    do j=1,iy
        jj=il+1-j
        cosg(j)=coa(j)
        cosg(jj)=coa(j)
        cosgr(j)=1./coa(j)
        cosgr(jj)=1./coa(j)
        cosgr2(j)=1./(coa(j)*coa(j))
        cosgr2(jj)=1./(coa(j)*coa(j))
    end do

    !  MM = zonal wavenumber = m
    !     ISC=3 implies that only wavenumber 0,3,6,9,etc are included in model
    !  LL = total wavenumber of spherical harmonic = l
    !  L2 = l*(l+1)
    !  EL2 = l*(l+1)/(a**2)
    !  EL4 = EL2*EL2 ; for biharmonic diffusion
    !  ELM2 = 1./EL2
    !  TRFILT used to filter out "non-triangular" part of rhomboidal truncation
    !   saved in mod_spectral
    do n=1,nx
        nsh2(n)=0
        do m=1,mx
            mm(m)=isc*(m-1)
            ll(m,n)=mm(m)+n-1
            l2(m,n)=ll(m,n)*(ll(m,n)+1)
            el2(m,n)=float(l2(m,n))*am2
            el4(m,n)=el2(m,n)*el2(m,n)
            if (ll(m,n).le.ntrun1.or.ix.ne.4*iy) nsh2(n)=nsh2(n)+2
            if (ll(m,n).le.ntrun) then
              trfilt(m,n)=1.
            else
              trfilt(m,n)=0.
            end if
        end do
    end do

    elm2(1,1)=0.
    do m=2,mx
        do n=1,nx
            elm2(m,n)=1./el2(m,n)
        end do
    end do

    do n=2,nx
        elm2(1,n)=1./el2(1,n)
    end do

    ! quantities needed to generate and differentiate Legendre polynomials
    ! all m values up to MXP = ISC*MTRUN+1 are needed by recursion relation 
    ! saved in mod_spectral
    do m=1,mxp
        do n=1,nxp
            emm(m)=float(m-1)
            ell(m,n)=float(n+m-2)
            emm2=emm(m)**2
            ell2=ell(m,n)**2
            if(n.eq.nxp) then
              epsi(m,n)=0.0
            else if(n.eq.1.and.m.eq.1) then
              epsi(m,n)=0.0
            else
              epsi(m,n)=sqrt((ell2-emm2)/(4.*ell2-1.))
            end if
            repsi(m,n)=0.0
            if(epsi(m,n).gt.0.) repsi(m,n)=1./epsi(m,n)
        end do
    end do

    sqrhlf=sqrt(.5)
    do m=2,mxp
        consq(m) = sqrt(.5*(2.*emm(m)+1.)/emm(m))
    end do

    ! quantities required by subroutines GRAD, UVSPEC, and VDS
    ! saved in mod_spectral
    do m=1,mx
        do n=1,nx
            m1=mm(m)
            m2=m1+1
            el1=float(ll(m,n))
            if(n.eq.1) then
                gradx(m)=float(m1)/a
                uvdx(m,1)=-a/float(m1+1)
                uvdym(m,1)=0.0
                vddym(m,1)=0.0
            else
                uvdx(m,n)=-a*float(m1)/(el1*(el1+1))
                gradym(m,n)=(el1-1.)*epsi(m2,n)/a
                uvdym(m,n)=-a*epsi(m2,n)/el1
                vddym(m,n)=(el1+1)*epsi(m2,n)/a
            end if
            gradyp(m,n)=(el1+2.)*epsi(m2,n+1)/a
            uvdyp(m,n)=-a*epsi(m2,n+1)/(el1+1.)
            vddyp(m,n)=el1*epsi(m2,n+1)/a
        end do
    end do

    !  generate associated Legendre polynomial
    !  LGNDRE computes the polynomials at a particular latitiude, POLY(MX,NX), and stores
    !  them in mod_spectral
    !  polynomials and 'clones' stored in mod_spectral
    do j=1,iy
        call lgndre_hr(j)
        do n=1,nx
            do m=1,mx
                m1=2*m-1
                m2=2*m
                cpol(m1,n,j)=poly(m,n)
                cpol(m2,n,j)=poly(m,n)
            end do
        end do
    end do
end
!****************************************************************
subroutine lgndre_hr(j)
    ! follows Leith Holloways code 

    use mod_atparam_hr
    use mod_spectral_hr, only: sia, coa, sqrhlf, consq, repsi, epsi, poly

    implicit none

    !include "param1spec.h"
    integer, intent(in) :: j
    real, parameter :: small = 1.e-30

    integer :: m, n, mm2
    real :: alp(mxp,nx), x, y
    y = coa(j)
    x = sia(j)

    ! start recursion with N=1 (M=L) diagonal 
    alp(1,1) = sqrhlf
    do m=2,mxp
        alp(m,1) = consq(m)*y*alp(m-1,1)
    end do
  
    ! continue with other elements
    do m=1,mxp
        alp(m,2)=(x*alp(m,1))*repsi(m,2)
    end do

    do n=3,nx
        do m=1,mxp
          alp(m,n)=(x*alp(m,n-1)-epsi(m,n-1)*alp(m,n-2))*repsi(m,n)
        end do
    end do

    ! zero polynomials with absolute values smaller than 10**(-30)
    do n=1,nx
        do m=1,mxp
            if(abs(alp(m,n)) .le. small) alp(m,n)=0.0
        end do
    end do

    ! pick off the required polynomials
    do n=1,nx
        do m=1,mx
            mm2=isc*(m-1)+1
            poly(m,n)=alp(mm2,n)
        end do
    end do
end

!******************************************************************
subroutine vds(ucosm,vcosm,vorm,divm)
    use mod_atparam_hr
    use mod_spectral_hr, only: gradx, vddyp, vddym

    implicit none

    !include "param1spec.h"
                                                        
    real, dimension(2,mx,nx) :: ucosm, vcosm
    real, dimension(2,mx,nx), intent(inout) :: vorm, divm
    real, dimension(2,mx,nx) :: zc, zp
    
    integer :: n, m, k

    do n=1,nx
        do m=1,mx
            zp(2,m,n)=gradx(m)*ucosm(1,m,n)
            zp(1,m,n)=-gradx(m)*ucosm(2,m,n)
            zc(2,m,n)=gradx(m)*vcosm(1,m,n)
            zc(1,m,n)=-gradx(m)*vcosm(2,m,n)
        end do
    end do

    do k=1,2
        do m=1,mx
            vorm(k,m,1)=zc(k,m,1)-vddyp(m,1)*ucosm(k,m,2)
            vorm(k,m,nx)=vddym(m,nx)*ucosm(k,m,ntrun1)
            divm(k,m,1)=zp(k,m,1)+vddyp(m,1)*vcosm(k,m,2)
            divm(k,m,nx)=-vddym(m,nx)*vcosm(k,m,ntrun1)
        end do
    end do

    do k=1,2
        do n=2,ntrun1
            do m=1,mx
                vorm(k,m,n)=vddym(m,n)*ucosm(k,m,n-1)-vddyp(m,n)*&
                    & ucosm(k,m,n+1)+zc(k,m,n)  
                divm(k,m,n)=-vddym(m,n)*vcosm(k,m,n-1)+vddyp(m,n)*&
                    & vcosm(k,m,n+1)+zp(k,m,n)
            end do
        end do
    end do
end
!*********************************************************************
subroutine spec(vorg,vorm)
    use mod_atparam_hr

    implicit none

    !include "param1spec.h"

    real, intent(inout) :: vorg(ix,il), vorm(mx2,nx)
    real :: varm(mx2,il)
    call specx(vorg,varm)
    call specy(varm,vorm)
end
!*********************************************************************
subroutine vdspec(ug,vg,vorm,divm,kcos)
    use mod_atparam_hr
    use mod_spectral_hr, only: cosgr, cosgr2

    implicit none

    !include "param1spec.h"

    real, intent(in) :: ug(ix,il), vg(ix,il)
    real, intent(inout) :: vorm(mx2,nx), divm(mx2,nx)
    integer, intent(in) :: kcos
    integer :: i, j
    real :: ug1(ix,il), vg1(ix,il), um(mx2,il), vm(mx2,il)
    real :: dumc1(mx2,nx), dumc2(mx2,nx)

    if (kcos.eq.2) then
        do j=1,il
            do i=1,ix
                ug1(i,j)=ug(i,j)*cosgr(j)
                vg1(i,j)=vg(i,j)*cosgr(j)
            end do
        end do
    else
        do j=1,il
            do i=1,ix
                ug1(i,j)=ug(i,j)*cosgr2(j)
                vg1(i,j)=vg(i,j)*cosgr2(j)
            end do
        end do
    end if

    call specx(ug1,um)  
    call specx(vg1,vm)
    call specy(um,dumc1)
    call specy(vm,dumc2)
    call vds(dumc1,dumc2,vorm,divm)
end
!******************************************************************
subroutine specy(varm,vorm)
    use mod_atparam_hr
    use mod_spectral_hr, only: wt, cpol, nsh2

    implicit none

    !include "param1spec.h"

    real, intent(in) :: varm(mx2,il)
    real, intent(inout) :: vorm(mx2,nx)
    real :: svarm(mx2,iy), dvarm(mx2,iy)

    integer :: j, j1, m, n

    vorm = 0.0

    do j=1,iy
        j1=il+1-j
        do m=1,mx2
            svarm(m,j)=(varm(m,j1)+varm(m,j))*wt(j)
            dvarm(m,j)=(varm(m,j1)-varm(m,j))*wt(j)
        end do
    end do

    do j=1,iy
        j1=il+1-j

        do n=1,ntrun1,2
            !do m=1,mx2
            do m=1,nsh2(n)
                vorm(m,n) = vorm(m,n)+cpol(m,n,j)*svarm(m,j)
            end do
        end do

        do n=2,ntrun1,2
            !do m=1,mx2
            do m=1,nsh2(n)
                vorm(m,n) = vorm(m,n)+cpol(m,n,j)*dvarm(m,j)
            end do
        end do
    end do
end
!******************************************************************
subroutine trunct(vor)
    use mod_atparam_hr
    use mod_spectral_hr, only: trfilt

    implicit none

    !include "param1spec.h"

    complex, intent(inout) :: vor(mx,nx)

    vor = vor * trfilt
end
