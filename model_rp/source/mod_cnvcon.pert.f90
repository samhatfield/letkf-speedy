!> @brief
!> Convection constants.
module mod_cnvcon
    use rp_emulator
    use mod_prec

    implicit none

    private
    public psmin, trcnv, rhbl, rhil, entmax, smf
    public init_cnvcon

    ! Minimum (norm.) sfc. pressure for the occurrence of convection
    real(dp), parameter :: psmin_ = 0.8_dp

    ! Time of relaxation (in hours) towards reference state
    real(dp), parameter :: trcnv_ = 4.0_dp

    ! Relative hum. threshold in the boundary layer
    real(dp), parameter :: rhbl_ = 0.8_dp

    ! Rel. hum. threshold in intermed. layers for secondary mass flux
    real(dp), parameter :: rhil_ = 0.9_dp

    ! Max. entrainment as a fraction of cloud-base mass flux
    real(dp), parameter :: entmax_ = 0.3_dp

    ! Ratio between secondary and primary mass flux at cloud-base
    real(dp), parameter :: smf_ = 0.7_dp

    ! Reduced precision versions
    type(rpe_var) :: psmin
    type(rpe_var) :: trcnv
    type(rpe_var) :: rhbl
    type(rpe_var) :: rhil
    type(rpe_var) :: entmax
    type(rpe_var) :: smf

    contains
        subroutine init_cnvcon
            psmin = psmin_
            trcnv = trcnv_
            rhbl = rhbl_
            rhil = rhil_
            entmax = entmax_
            smf = smf_
        end subroutine
end module
