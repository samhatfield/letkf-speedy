module mod_fft_hr
    use mod_atparam_hr, only: ix

    implicit none

    private
    public wsave

    real :: wsave(2*ix+15)
end module
