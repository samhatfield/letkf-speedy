!> @brief
!> Constants for vertical diffusion and shallow convection.
module mod_vdicon
    use rp_emulator
    use mod_prec

    implicit none

    private
    public trshc, trvdi, trvds, redshc, rhgrad, segrad
    public init_vdicon

    ! Relaxation time (in hours) for shallow convection
    real(dp), parameter :: trshc_ = 6.0

    ! Relaxation time (in hours) for moisture diffusion
    real(dp), parameter :: trvdi_ = 24.0

    ! Relaxation time (in hours) for super-adiab. conditions
    real(dp), parameter :: trvds_ = 6.0

    ! Reduction factor of shallow conv. in areas of deep conv.
    real(dp), parameter :: redshc_ = 0.5

    ! Maximum gradient of relative humidity (d_RH/d_sigma)
    real(dp), parameter :: rhgrad_ = 0.5

    ! Minimum gradient of dry static energy (d_DSE/d_phi)
    real(dp), parameter :: segrad_ = 0.1

    ! Reduced precision versions
    type(rpe_var) :: trshc
    type(rpe_var) :: trvdi
    type(rpe_var) :: trvds
    type(rpe_var) :: redshc
    type(rpe_var) :: rhgrad
    type(rpe_var) :: segrad

    contains
        subroutine init_vdicon
            trshc = trshc_
            trvdi = trvdi_
            trvds = trvds_
            redshc = redshc_
            rhgrad = rhgrad_
            segrad = segrad_
        end subroutine
end module
