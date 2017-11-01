module mod_prec
    use, intrinsic :: iso_fortran_env

    implicit none

    private
    public dp, sp

    integer, parameter :: dp = real64
    integer, parameter :: sp = real32
end module
