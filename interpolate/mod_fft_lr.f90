module mod_fft_lr
    use mod_atparam_lr, only: ix

    implicit none

    private
    public wsave

    real :: wsave(2*ix+15)
end module
