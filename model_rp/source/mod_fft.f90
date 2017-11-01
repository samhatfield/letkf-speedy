module mod_fft
    use mod_atparam, only: ix
    use rp_emulator

    implicit none

    private
    public wsave

    type(rpe_var) :: wsave(2*ix+15)
end module
