module mod_radcon
    use mod_atparam
    use rp_emulator
    use mod_prec

    implicit none

    private
    public solc, albsea, albice, albsn, rhcl1, rhcl2, qacl, wpcl, pmaxcl,&
        & clsmax, clsminl, gse_s0, gse_s1, albcl, albcls, epssw,  epslw, emisfc,&
        & absdry, absaer, abswv1, abswv2, abscl1, abscl2, ablwin, ablco2,&
        & ablco2_ref, ablwv1, ablwv2, ablcl1, ablcl2
    public fband
    public fsol, ozone, ozupp, zenit, stratz
    public alb_l, alb_s, albsfc, snowc
    public tau2, st4a, stratc, flux
    public qcloud, irhtop
    public init_radcon

    ! Radiation and cloud constants
    
    ! solc   = Solar constant (area averaged) in W/m^2
    ! albsea = Albedo over sea 
    ! albice = Albedo over sea ice (for ice fraction = 1)
    ! albsn  = Albedo over snow (for snow cover = 1)
    
    ! rhcl1  = relative hum. threshold corr. to cloud cover = 0
    ! rhcl2  = relative hum. corr. to cloud cover = 1
    ! qacl   = specific hum. threshold for cloud cover
    ! wpcl   = cloud c. weight for the sq. root of precip. (for p = 1 mm/day)
    ! pmaxcl = max. value of precip. (mm/day) contributing to cloud cover 
    
    ! clsmax = maximum stratiform cloud cover
    ! clsminl= minimum stratiform cloud cover over land (for RH = 1)
    ! gse_s0 = gradient of dry static energy corresp. to strat.c.c. = 0
    ! gse_s1 = gradient of dry static energy corresp. to strat.c.c. = 1
    
    ! albcl  = cloud albedo (for cloud cover = 1)
    ! albcls = stratiform cloud albedo (for st. cloud cover = 1)
    ! epssw  = fraction of incoming solar radiation absorbed by ozone
    ! epslw  = fraction of blackbody spectrum absorbed/emitted by PBL only
    ! emisfc = longwave surface emissivity
    
    !          shortwave absorptivities (for dp = 10^5 Pa) :
    ! absdry = abs. of dry air      (visible band)
    ! absaer = abs. of aerosols     (visible band)
    ! abswv1 = abs. of water vapour (visible band, for dq = 1 g/kg)
    ! abswv2 = abs. of water vapour (near IR band, for dq = 1 g/kg)
    ! abscl2 = abs. of clouds       (visible band, for dq_base = 1 g/kg)
    ! abscl1 = abs. of clouds       (visible band, maximum value)
    
    !          longwave absorptivities (per dp = 10^5 Pa) :
    ! ablwin = abs. of air in "window" band
    ! ablco2 = abs. of air in CO2 band
    ! ablwv1 = abs. of water vapour in H2O band 1 (weak),   for dq = 1 g/kg
    ! ablwv2 = abs. of water vapour in H2O band 2 (strong), for dq = 1 g/kg
    ! ablcl1 = abs. of "thick" clouds in window band (below cloud top) 
    ! ablcl2 = abs. of "thin" upper clouds in window and H2O bands

    real(dp), parameter :: solc_ = 342.0

    real(dp), parameter :: albsea_ = 0.07
    real(dp), parameter :: albice_ = 0.60!0.75
    real(dp), parameter :: albsn_  = 0.60

    real(dp), parameter :: rhcl1_  =  0.30
    real(dp), parameter :: rhcl2_  =  1.00
    real(dp), parameter :: qacl_   =  0.20
    real(dp), parameter :: wpcl_   =  0.2
    real(dp), parameter :: pmaxcl_ = 10.0

    real(dp), parameter :: clsmax_  = 0.60!0.50
    real(dp), parameter :: clsminl_ = 0.15
    real(dp), parameter :: gse_s0_  = 0.25
    real(dp), parameter :: gse_s1_  = 0.40

    real(dp), parameter :: albcl_  =  0.43
    real(dp), parameter :: albcls_ =  0.50

    real(dp), parameter :: epssw_  =  0.020!0.025
    real(dp), parameter :: epslw_  =  0.05
    real(dp), parameter :: emisfc_ =  0.98

    real(dp), parameter :: absdry_ =  0.033
    real(dp), parameter :: absaer_ =  0.033
    real(dp), parameter :: abswv1_ =  0.022
    real(dp), parameter :: abswv2_ = 15.000

    real(dp), parameter :: abscl1_ =  0.015
    real(dp), parameter :: abscl2_ =  0.15

    real(dp), parameter :: ablwin_ =  0.3
    real(dp), parameter :: ablco2_ =  6.0!5.0
    real(dp), parameter :: ablwv1_ =  0.7
    real(dp), parameter :: ablwv2_ = 50.0

    real(dp), parameter :: ablcl1_ = 12.0
    real(dp), parameter :: ablcl2_ =  0.6
    type(rpe_var) :: ablco2_ref

    ! Time-invariant fields (initial. in radset)
    ! fband  = energy fraction emitted in each LW band = f(T)
    type(rpe_var) :: fband(100:400,4)

    ! Zonally-averaged fields for SW/LW scheme (updated in sol_oz)
    ! fsol   = flux of incoming solar radiation
    ! ozone  = flux absorbed by ozone (lower stratos.)
    ! ozupp  = flux absorbed by ozone (upper stratos.)
    ! zenit  = optical depth ratio (function of solar zenith angle)
    ! stratz = stratospheric correction for polar night
    type(rpe_var), dimension(ix*il) :: fsol, ozone, ozupp, zenit, stratz

    ! Radiative properties of the surface (updated in fordate)
    ! alb_l  = daily-mean albedo over land (bare-land + snow)
    ! alb_s  = daily-mean albedo over sea  (open sea + sea ice)
    ! albsfc = combined surface albedo (land + sea)
    ! snowc  = effective snow cover (fraction)
    type(rpe_var), dimension(ix*il) :: alb_l, alb_s, albsfc, snowc

    ! Transmissivity and blackbody rad. (updated in radsw/radlw)
    ! tau2   = transmissivity of atmospheric layers
    ! st4a   = blackbody emission from full and half atmospheric levels
    ! stratc = stratospheric correction term 
    ! flux   = radiative flux in different spectral bands
    type(rpe_var) :: tau2(ix*il,kx,4), st4a(ix*il,kx,2), stratc(ix*il,2), flux(ix*il,4)

    ! Radiative properties of clouds (updated in cloud)
    ! qcloud = Equivalent specific humidity of clouds 
    type(rpe_var), dimension(ix*il) :: qcloud, irhtop

    ! Reduced precision versions
    type(rpe_var) :: solc
    type(rpe_var) :: albsea
    type(rpe_var) :: albice
    type(rpe_var) :: albsn
    type(rpe_var) :: rhcl1
    type(rpe_var) :: rhcl2
    type(rpe_var) :: qacl
    type(rpe_var) :: wpcl
    type(rpe_var) :: pmaxcl
    type(rpe_var) :: clsmax
    type(rpe_var) :: clsminl
    type(rpe_var) :: gse_s0
    type(rpe_var) :: gse_s1
    type(rpe_var) :: albcl
    type(rpe_var) :: albcls
    type(rpe_var) :: epssw
    type(rpe_var) :: epslw
    type(rpe_var) :: emisfc
    type(rpe_var) :: absdry
    type(rpe_var) :: absaer
    type(rpe_var) :: abswv1
    type(rpe_var) :: abswv2
    type(rpe_var) :: abscl1
    type(rpe_var) :: abscl2
    type(rpe_var) :: ablwin
    type(rpe_var) :: ablco2
    type(rpe_var) :: ablwv1
    type(rpe_var) :: ablwv2
    type(rpe_var) :: ablcl1
    type(rpe_var) :: ablcl2

    contains
        subroutine init_radcon
            solc   = solc_
            albsea = albsea_
            albice = albice_
            albsn  = albsn_
            rhcl1  = rhcl1_
            rhcl2  = rhcl2_
            qacl   = qacl_
            wpcl   = wpcl_
            pmaxcl = pmaxcl_
            clsmax = clsmax_
            clsminl= clsminl_
            gse_s0 = gse_s0_
            gse_s1 = gse_s1_
            albcl  = albcl_
            albcls = albcls_
            epssw  = epssw_
            epslw  = epslw_
            emisfc = emisfc_
            absdry = absdry_
            absaer = absaer_
            abswv1 = abswv1_
            abswv2 = abswv2_
            abscl1 = abscl1_
            abscl2 = abscl2_
            ablwin = ablwin_
            ablco2 = ablco2_
            ablwv1 = ablwv1_
            ablwv2 = ablwv2_
            ablcl1 = ablcl1_
            ablcl2 = ablcl2_
        end subroutine
end module
