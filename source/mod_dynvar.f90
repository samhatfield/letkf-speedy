!> @brief
!> Prognostic spectral variables for model dynamics, and geopotential.
!> Initialised in invars.
module mod_dynvar
    use mod_atparam
	use rp_emulator

    implicit none

    private
    public vor, div, t, ps, tr
    public phi, phis

    ! Prognostic spectral variables (updated in step)
    ! Vorticity
    type(rpe_complex_var) :: vor(MX,NX,KX,2)

    ! Divergence 
    type(rpe_complex_var) :: div(MX,NX,KX,2)

    ! Absolute temperature
    type(rpe_complex_var) :: t(MX,NX,KX,2)

    ! Log of (norm.) sfc pressure (p_s/p0)
    type(rpe_complex_var) :: PS(MX,NX,2)

    ! Tracers (tr.1: spec. humidity in g/kg)
    type(rpe_complex_var) :: TR(MX,NX,KX,2,NTR)

    ! Geopotential (updated in geop)
    ! Atmos. geopotential
    type(rpe_complex_var) :: PHI(MX,NX,KX)

    ! Surface geopotential
    type(rpe_complex_var) :: PHIS(MX,NX)
end module
