!> @brief
!> Constants for large-scale condensation.
module mod_lsccon
    use rp_emulator
    use mod_prec

    implicit none

    private
    public trlsc, rhlsc, drhlsc, rhblsc
    public init_lsccon

    ! Relaxation time (in hours) for specific humidity 
    real(dp), parameter :: trlsc_  = 4.0_dp

    ! Maximum relative humidity threshold (at sigma=1)
    real(dp), parameter :: rhlsc_  = 0.9_dp

    ! Vertical range of relative humidity threshold
    real(dp), parameter :: drhlsc_ = 0.1_dp

    ! Relative humidity threshold for boundary layer
    real(dp), parameter :: rhblsc_ = 0.95_dp

    ! Reduced precision versions
    type(rpe_var) :: trlsc
    type(rpe_var) :: rhlsc
    type(rpe_var) :: drhlsc
    type(rpe_var) :: rhblsc

    contains
        subroutine init_lsccon
            trlsc = trlsc_
            rhlsc = rhlsc_
            drhlsc = drhlsc_
            rhblsc = rhblsc_
        end subroutine
end module
