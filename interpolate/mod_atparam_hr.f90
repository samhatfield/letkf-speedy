module mod_atparam_hr
    implicit none

    private
    public isc, ntrun, mtrun, ix, iy
    public nx, mx, mxnx, mx2, il, ntrun1, nxp, mxp, lmax
    public kx, kx2, kxm, kxp, ntr
    public nlon0, nlat0, ngp0

    integer, parameter :: isc = 1
    integer, parameter :: ntrun = 39, mtrun = 39, ix = 120, iy = 30
    integer, parameter :: nx = ntrun+2, mx = mtrun+1, mxnx = mx*nx, mx2 = 2*mx
    integer, parameter :: il = 2*iy, ntrun1 = ntrun+1
    integer, parameter :: nxp = nx+1 , mxp = isc*mtrun+1, lmax = mxp+nx-2
    integer, parameter :: kx = 8, kx2=2*kx, kxm=kx-1, kxp=kx+1, ntr=1

!   integer, parameter :: nlon0 = 360, nlat0 = 180, ngp0 = nlon0*nlat0
    integer, parameter :: nlon0 = 120, nlat0 = 60, ngp0 = nlon0*nlat0
end module
