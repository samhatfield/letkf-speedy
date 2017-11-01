subroutine inifft_lr
    ! Initialize FFTs

    use mod_atparam_lr, only: ix
    use mod_fft_lr

    implicit none

    call rffti(ix,wsave)
    !call dffti (ix,wsave)
end

!*********************************************************************

subroutine gridx(varm,vorg,kcos)
    ! From Fourier coefficients to grid-point data

    use mod_atparam_lr
    use mod_spectral_lr, only: cosgr
    use mod_fft_lr

    implicit none

    real, intent(in) :: varm(mx2,il)
    real, intent(inout) :: vorg(ix,il)
    integer, intent(in) :: kcos
    integer :: j, m
    real :: fvar(ix)

	do j = 1,il
		fvar(1) = varm(1,j)

        do m=3,mx2
          fvar(m-1)=varm(m,j)
        end do
        do m=mx2,ix
          fvar(m)=0.0
        end do

        ! Inverse FFT
        call rfftb(ix,fvar,wsave)
        !call dfftb(ix,fvar,wsave)

        ! Copy output into grid-point field, scaling by cos(lat) if needed
        if (kcos.eq.1) then
            vorg(:,j) = fvar
        else
            vorg(:,j) = fvar * cosgr(j)
        end if
    end do
end
