module mod_sflcon
    use mod_atparam
    use rp_emulator
    use mod_prec

    implicit none

    private
    public fwind0, ftemp0, fhum0, cdl, cds, chl, chs, vgust, ctday, dtheta,&
        & fstab, hdrag, fhdrag, clambda, clambsn, forog
    public init_sflcon

    !  Constants for surface fluxes
    ! Ratio of near-sfc wind to lowest-level wind
    real(dp), parameter :: fwind0_ = 0.95_dp

    ! Weight for near-sfc temperature extrapolation (0-1) :
    !          1 : linear extrapolation from two lowest levels
    !          0 : constant potential temperature ( = lowest level)
    real(dp), parameter :: ftemp0_ = 1.0_dp

    ! Weight for near-sfc specific humidity extrapolation (0-1) :
    !            1 : extrap. with constant relative hum. ( = lowest level)
    !            0 : constant specific hum. ( = lowest level)
    real(dp), parameter :: fhum0_ = 0.0_dp

    ! Drag coefficient for momentum over land
    real(dp), parameter :: cdl_ = 2.4d-3

    ! Drag coefficient for momentum over sea
    real(dp), parameter :: cds_ = 1.0d-3

    ! Heat exchange coefficient over land
    real(dp), parameter :: chl_ = 1.2d-3

    ! Heat exchange coefficient over sea
    real(dp), parameter :: chs_ = 0.9d-3

    ! Wind speed for sub-grid-scale gusts
    real(dp), parameter :: vgust_ = 5.0_dp

    ! Daily-cycle correction (dTskin/dSSRad)
    real(dp), parameter :: ctday_ = 1.0d-2

    ! Potential temp. gradient for stability correction
    real(dp), parameter :: dtheta_ = 3.0_dp

    ! Amplitude of stability correction (fraction)
    real(dp), parameter :: fstab_ = 0.67_dp

    ! Height scale for orographic correction
    real(dp), parameter :: hdrag_ = 2000.0_dp

    ! Amplitude of orographic correction (fraction)
    real(dp), parameter :: fhdrag_ = 0.5_dp

    ! Heat conductivity in skin-to-root soil layer
    real(dp), parameter :: clambda_ = 7.0_dp

    ! Heat conductivity in soil for snow cover = 1
    real(dp), parameter :: clambsn_ = 7.0_dp

    ! Time-invariant fields (initial. in SFLSET)
    type(rpe_var) :: forog(ix*il)

    ! Reduced precision versions
    type(rpe_var) :: fwind0
    type(rpe_var) :: ftemp0
    type(rpe_var) :: fhum0
    type(rpe_var) :: cdl
    type(rpe_var) :: cds
    type(rpe_var) :: chl
    type(rpe_var) :: chs
    type(rpe_var) :: vgust
    type(rpe_var) :: ctday
    type(rpe_var) :: dtheta
    type(rpe_var) :: fstab
    type(rpe_var) :: hdrag
    type(rpe_var) :: fhdrag
    type(rpe_var) :: clambda
    type(rpe_var) :: clambsn

    contains
        subroutine init_sflcon
            fwind0  = fwind0_
            ftemp0  = ftemp0_
            fhum0   = fhum0_
            cdl     = cdl_
            cds     = cds_
            chl     = chl_
            chs     = chs_
            vgust   = vgust_
            ctday   = ctday_
            dtheta  = dtheta_
            fstab   = fstab_
            hdrag   = hdrag_
            fhdrag  = fhdrag_
            clambda = clambda_
            clambsn = clambsn_
        end subroutine
end module
