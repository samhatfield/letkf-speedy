subroutine inifft_hr
    ! Initialize FFTs

    use mod_atparam_hr, only: ix
    use mod_fft_hr

    implicit none

    call rffti(ix,wsave)
    !call dffti (ix,wsave)
end

!******************************************************************

subroutine specx(vorg,varm)
    ! From grid-point data to Fourier coefficients

    use mod_atparam_hr
    use mod_fft_hr

    implicit none

    real, intent(in) :: vorg(ix,il)
    real, intent(inout) :: varm(mx2,il)
    integer :: j, m
    real :: fvar(ix), scale

    ! Copy grid-point data into working array
    do j=1,il
        fvar = vorg(:,j)

        ! Direct FFT
        CALL RFFTF (IX,FVAR,WSAVE)
        !CALL DFFTF (IX,FVAR,WSAVE)

        ! Copy output into spectral field, dividing by no. of long.
        scale=1./float(ix)

        ! Mean value (a(0))
        varm(1,j)=fvar(1)*scale
        varm(2,j)=0.0

        do m=3,mx2
            varm(m,j)=fvar(m-1)*scale
        end do
    end do
end

include "spe_subfft_fftpack2.f90"
