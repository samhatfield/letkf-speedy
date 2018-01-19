subroutine truncate
    use mod_fft
    use mod_spectral

    call truncate_fft
    call truncate_spectral
end subroutine
