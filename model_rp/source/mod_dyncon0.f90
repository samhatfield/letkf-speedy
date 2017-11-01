!> @brief
!> Constants for initialization of dynamics.
module mod_dyncon0
    use rp_emulator
    use mod_prec

    implicit none

    private
    public gamma, hscale, hshum, refrh1, thd, thdd, thds, tdrs
    public init_dyncon0

    ! Ref. temperature lapse rate (-dT/dz in deg/km)
    real(dp), parameter :: gamma_ = 6.0_dp

    ! Ref. scale height for pressure (in km)
    real(dp), parameter :: hscale_ = 7.5_dp

    ! Ref. scale height for spec. humidity (in km)
    real(dp), parameter :: hshum_ = 2.5_dp

    ! Ref. relative humidity of near-surface air
    real(dp), parameter :: refrh1_ = 0.7_dp

    ! Max damping time (in hours) for hor. diffusion (del^6) of temperature and
    ! vorticity
    real(dp), parameter :: thd_ = 2.4_dp

    ! Max damping time (in hours) for hor. diffusion (del^6)
    ! of divergence
    real(dp), parameter :: thdd_ = 2.4_dp

    ! Max damping time (in hours) for extra diffusion (del^2)
    ! in the stratosphere 
    real(dp), parameter :: thds_ = 12.0_dp

    ! Damping time (in hours) for drag on zonal-mean wind
    ! in the stratosphere 
    real(dp), parameter :: tdrs_ = 24.0_dp * 30.0_dp

    ! Reduced precision versions
    type(rpe_var) :: gamma
    type(rpe_var) :: hscale
    type(rpe_var) :: hshum
    type(rpe_var) :: refrh1
    type(rpe_var) :: thd
    type(rpe_var) :: thdd
    type(rpe_var) :: thds
    type(rpe_var) :: tdrs

    contains
        subroutine init_dyncon0
            gamma = gamma_
            hscale = hscale_
            hshum = hshum_
            refrh1 = refrh1_
            thd = thd_
            thdd = thdd_
            thds = thds_
            tdrs = tdrs_
        end subroutine
end module
