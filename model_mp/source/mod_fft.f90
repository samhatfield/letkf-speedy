module mod_fft
    use mod_atparam, only: ix
    use rp_emulator

    implicit none

    private
    public wsave
    public truncate_fft

    type(rpe_var) :: wsave(2*ix+15)

    contains
        subroutine truncate_fft
            ! For some reason the 193rd, 194th and 195th elements are very
            ! important, even though they are on the order of 10^-314. I can't
            ! reduce precision for them as they would be rounded to zero.
            wsave(1:192) = wsave(1:192)
            wsave(196:) = wsave(196:)
        end subroutine
end module
