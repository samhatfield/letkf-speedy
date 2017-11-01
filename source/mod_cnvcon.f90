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
    real(dp), parameter :: psmin_ = 0.8

    ! Time of relaxation (in hours) towards reference state
    real(dp), parameter :: trcnv_ = 6.0

    ! Relative hum. threshold in the boundary layer
    real(dp), parameter :: rhbl_ = 0.9

    ! Rel. hum. threshold in intermed. layers for secondary mass flux
    real(dp), parameter :: rhil_ = 0.7

    ! Max. entrainment as a fraction of cloud-base mass flux
    real(dp), parameter :: entmax_ = 0.5

    ! Ratio between secondary and primary mass flux at cloud-base
    real(dp), parameter :: smf_ = 0.8

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
