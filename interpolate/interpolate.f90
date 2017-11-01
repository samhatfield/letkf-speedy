program interpolate
    use mod_atparam_hr, nlon_hr => ix, nlat_hr => il, mx_hr => mx, nx_hr => nx
    use mod_atparam_lr, nlon_lr => ix, nlat_lr => il, mx_lr => mx, nx_lr => nx

    implicit none

    integer :: irec, k, j, m, n
    integer, parameter :: ngp_hr=nlon_hr*nlat_hr, ngp_lr=nlon_lr*nlat_lr

    ! High res variables
    real(4), dimension(ngp_hr,8) :: ugr4_hr, vgr4_hr, tgr4_hr, qgr4_hr, phigr4_hr
    real(4), dimension(ngp_hr) :: psgr4_hr, rrgr4_hr
    real, dimension(ngp_hr,kx) :: ugr_hr, vgr_hr, tgr_hr, qgr_hr, phigr_hr
    real, dimension(ngp_hr) :: psgr_hr, rrgr_hr
    complex, dimension(mx_hr,nx_hr,kx,2) :: vor_hr, div_hr, t_hr
    complex, dimension(mx_hr,nx_hr,kx,2,ntr) :: tr_hr
    complex, dimension(mx_hr,nx_hr,2) :: ps_hr, rr_hr

    ! Low res variables
    real(4), dimension(ngp_lr,kx) :: ugr4_lr, vgr4_lr, tgr4_lr, qgr4_lr, phigr4_lr
    real(4), dimension(ngp_lr) :: psgr4_lr, rrgr4_lr
    real, dimension(ngp_lr,kx) :: ugr_lr, vgr_lr, tgr_lr, qgr_lr, phigr_lr
    real, dimension(ngp_lr) :: psgr_lr, rrgr_lr
    complex, dimension(mx_lr,nx_lr,kx,2) :: vor_lr, div_lr, t_lr
    complex, dimension(mx_lr,nx_lr,kx,2,ntr) :: tr_lr
    complex, dimension(mx_lr,nx_lr,2) :: ps_lr, rr_lr
    complex, dimension(mx_lr,nx_lr) :: ucostmp, vcostmp

    ! Reference pressure
    real, parameter :: p0 = 1.e+5

    ! Earth radius
    real, parameter :: rearth = 6.371e+6

    integer, parameter :: iitest = 0

    ! Initialize FFT
    call inifft_hr
    call parmtr_hr(rearth)

    ! Read in T39 (120x60) grid point file
    open (unit=90, file='true.grd', form='unformatted',access='direct',recl=4*ngp_hr)
    irec=1
    do k=kx,1,-1
        read (90,rec=irec) (ugr4_hr(j,k),j=1,ngp_hr)
        irec=irec+1
    end do
    do k=kx,1,-1
        read (90,rec=irec) (vgr4_hr(j,k),j=1,ngp_hr)
        irec=irec+1
    end do
    do k=kx,1,-1
        read (90,rec=irec) (tgr4_hr(j,k),j=1,ngp_hr)
        irec=irec+1
    end do
    do k=kx,1,-1
        read (90,rec=irec) (qgr4_hr(j,k),j=1,ngp_hr)
        irec=irec+1
    end do
    read (90,rec=irec) (psgr4_hr(j),j=1,ngp_hr)
    irec=irec+1
    read (90,rec=irec) (rrgr4_hr(j),j=1,ngp_hr)
    close (90)

    ugr_hr = ugr4_hr
    vgr_hr = vgr4_hr
    tgr_hr = tgr4_hr
    qgr_hr = qgr4_hr *1.0d3
    psgr_hr = psgr4_hr
    psgr_hr = log(psgr_hr/p0)
    rrgr_hr = rrgr4_hr
    if(iitest==1) print *,' UGR  :',minval(ugr_hr),maxval(ugr_hr)
    if(iitest==1) print *,' VGR  :',minval(vgr_hr),maxval(vgr_hr)
    if(iitest==1) print *,' TGR  :',minval(tgr_hr),maxval(tgr_hr)
    if(iitest==1) print *,' QGR  :',minval(qgr_hr),maxval(qgr_hr)
    if(iitest==1) print *,' PSGR :',minval(psgr_hr),maxval(psgr_hr)
    if(iitest==1) print *,' RRGR :',minval(rrgr_hr),maxval(rrgr_hr)

    ! Conversion from gridded variable to spectral variable
    do k=1,kx
        call vdspec(ugr_hr(1,k),vgr_hr(1,k),vor_hr(1,1,k,1),div_hr(1,1,k,1),2)
        call trunct(vor_hr(1,1,k,1))
        call trunct(div_hr(1,1,k,1))
        call spec(tgr_hr(1,k),t_hr(1,1,k,1))
        call spec(qgr_hr(1,k),tr_hr(1,1,k,1,1))
    end do
    call spec(psgr_hr(1),ps_hr(1,1,1))
    call spec(rrgr_hr(1),rr_hr(1,1,1))

    ! Truncate to T30
    do k=1,kx
        vor_lr(:,:,k,1)  = truncate(vor_hr(:,:,k,1), 30)
        div_lr(:,:,k,1)  = truncate(div_hr(:,:,k,1), 30)
        t_lr(:,:,k,1)    = truncate(t_hr(:,:,k,1), 30)
        tr_lr(:,:,k,1,1) = truncate(tr_hr(:,:,k,1,1), 30)
    end do
    ps_lr(:,:,1)  = truncate(ps_hr(:,:,1), 30)
    rr_lr(:,:,1)  = truncate(rr_hr(:,:,1), 30)

    ! Convert back to grid point space (96x48)
    call inifft_lr
    call parmtr_lr(rearth)

    do k=1,kx
        call uvspec(vor_lr(1,1,k,1),div_lr(1,1,k,1),ucostmp,vcostmp)
        call grid(ucostmp,ugr_lr(1,k),2)
        call grid(vcostmp,vgr_lr(1,k),2)
    end do

    do k=1,kx
        call grid(t_lr(1,1,k,1),tgr_lr(1,k),1)
        call grid(tr_lr(1,1,k,1,1),qgr_lr(1,k),1)
    end do

    call grid(ps_lr(1,1,1),psgr_lr(1),1)
    call grid(rr_lr(1,1,1),rrgr_lr(1),1)

    if(iitest==1) print *,' UGR  :',minval(ugr_lr),maxval(ugr_lr)
    if(iitest==1) print *,' VGR  :',minval(vgr_lr),maxval(vgr_lr)
    if(iitest==1) print *,' TGR  :',minval(tgr_lr),maxval(tgr_lr)
    if(iitest==1) print *,' QGR  :',minval(qgr_lr),maxval(qgr_lr)
    if(iitest==1) print *,' PSGR :',minval(psgr_lr),maxval(psgr_lr)
    if(iitest==1) print *,' RRGR :',minval(rrgr_lr),maxval(rrgr_lr)

    ! Write to output file
    ugr4_lr = ugr_lr
    vgr4_lr = vgr_lr
    tgr4_lr = tgr_lr
    qgr4_lr = qgr_lr*1.0d-3 ! kg/kg
    psgr4_lr = p0*exp(psgr_lr)! Pa
    rrgr4_lr = rrgr_lr

    open (99,file='out.grd',form='unformatted',access='direct',recl=4*ngp_lr)
    irec=1
    do k=kx,1,-1
        write (99,rec=irec) (ugr4_lr(j,k),j=1,ngp_lr)
        irec=irec+1
    end do
    do k=kx,1,-1
        write (99,rec=irec) (vgr4_lr(j,k),j=1,ngp_lr)
        irec=irec+1
    end do
    do k=kx,1,-1
        write (99,rec=irec) (tgr4_lr(j,k),j=1,ngp_lr)
        irec=irec+1
    end do
    do k=kx,1,-1
        write (99,rec=irec) (qgr4_lr(j,k),j=1,ngp_lr)
        irec=irec+1
    end do
    write (99,rec=irec) (psgr4_lr(j),j=1,ngp_lr)
    irec=irec+1
    write (99,rec=irec) (rrgr4_lr(j),j=1,ngp_lr)
    close (99)

    contains
        function truncate(field_hr, trunc_twn) result(field_lr)
            complex, intent(in) :: field_hr(mx_hr,nx_hr)
            integer, intent(in) :: trunc_twn
            complex :: field_lr(mx_lr,nx_lr)

            do m = 1,mx_lr
                do n = 1,nx_lr
                    field_lr(m,n) = field_hr(m,n)

                    if (m+n-2 > trunc_twn) then
                        field_lr(m,n) = (0.0,0.0)
                    end if
                end do
            end do
        end function
end program interpolate
