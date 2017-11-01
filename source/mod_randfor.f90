module mod_randfor
    use mod_atparam
    use rp_emulator

    implicit none

    private
    public randfh, randfv

    ! Random diabatic forcing (initial. in INIRDF, modified by XS_RDF))
    type(rpe_var) :: randfh(ix,il,2), randfv(il,kx,2)
end module
