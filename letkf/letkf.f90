PROGRAM letkf
!=======================================================================
!
! [PURPOSE:] Main program of LETKF
!
! [HISTORY:]
!   01/16/2009 Takemasa Miyoshi  created
!
!=======================================================================
!$USE OMP_LIB
  USE common
  USE common_mpi
  USE common_speedy
  USE common_mpi_speedy
  USE common_letkf
  USE letkf_obs
  USE letkf_tools

  IMPLICIT NONE
  REAL(r_size),ALLOCATABLE :: gues3d(:,:,:,:)
  REAL(r_size),ALLOCATABLE :: gues2d(:,:,:)
  REAL(r_size),ALLOCATABLE :: adin3d(:,:,:,:)
  REAL(r_size),ALLOCATABLE :: adin2d(:,:,:)
  REAL(r_size),ALLOCATABLE :: anal3d(:,:,:,:)
  REAL(r_size),ALLOCATABLE :: anal2d(:,:,:)
  REAL(r_size),ALLOCATABLE :: adin3dmean(:,:,:)
  REAL(r_size),ALLOCATABLE :: adin2dmean(:,:)
  LOGICAL, PARAMETER :: add_infl = .false.
  REAL(r_size) :: rtimer00,rtimer
  INTEGER :: ierr, j
  CHARACTER(8) :: stdoutf='NOUT-000'
  CHARACTER(4) :: guesf='gs00'
!-----------------------------------------------------------------------
! Initial settings
!-----------------------------------------------------------------------
  CALL CPU_TIME(rtimer00)
  CALL initialize_mpi

  WRITE(stdoutf(6:8), '(I3.3)') myrank
  WRITE(6,'(3A,I3.3)') 'STDOUT goes to ',stdoutf,' for MYRANK ', myrank
  OPEN(6,FILE=stdoutf)
  WRITE(6,'(A,I3.3,2A)') 'MYRANK=',myrank,', STDOUTF=',stdoutf

  WRITE(6,'(A)') '============================================='
  WRITE(6,'(A)') '  LOCAL ENSEMBLE TRANSFORM KALMAN FILTERING  '
  WRITE(6,'(A)') '                                             '
  WRITE(6,'(A)') '   LL      EEEEEE  TTTTTT  KK  KK  FFFFFF    '
  WRITE(6,'(A)') '   LL      EE        TT    KK KK   FF        '
  WRITE(6,'(A)') '   LL      EEEEE     TT    KKK     FFFFF     '
  WRITE(6,'(A)') '   LL      EE        TT    KK KK   FF        '
  WRITE(6,'(A)') '   LLLLLL  EEEEEE    TT    KK  KK  FF        '
  WRITE(6,'(A)') '                                             '
  WRITE(6,'(A)') '             WITHOUT LOCAL PATCH             '
  WRITE(6,'(A)') '                                             '
  WRITE(6,'(A)') '          Coded by Takemasa Miyoshi          '
  WRITE(6,'(A)') '  Based on Ott et al (2004) and Hunt (2005)  '
  WRITE(6,'(A)') '  Tested by Miyoshi and Yamane (2006)        '
  WRITE(6,'(A)') '============================================='
  WRITE(6,'(A)') '              LETKF PARAMETERS               '
  WRITE(6,'(A)') ' ------------------------------------------- '
  WRITE(6,'(A,I15)')   '   n_ens        :',n_ens
  WRITE(6,'(A,I15)')   '   nslots     :',nslots
  WRITE(6,'(A,I15)')   '   nbslot     :',nbslot
  WRITE(6,'(A,F15.2)') '   sigma_obs  :',sigma_obs
  WRITE(6,'(A,F15.2)') '   sigma_obsv :',sigma_obsv
  WRITE(6,'(A,F15.2)') '   sigma_obst :',sigma_obst
  WRITE(6,'(A)') '============================================='
  CALL set_common_speedy
  CALL set_common_mpi_speedy
  ALLOCATE(gues3d(nij1,nlev,n_ens,nv3d))
  ALLOCATE(gues2d(nij1,n_ens,nv2d))
  if (add_infl) then
      ALLOCATE(adin3d(nij1,nlev,n_ens,nv3d))
      ALLOCATE(adin2d(nij1,n_ens,nv2d))
      ALLOCATE(adin3dmean(nij1,nlev,nv3d))
      ALLOCATE(adin2dmean(nij1,nv2d))
  end if
  ALLOCATE(anal3d(nij1,nlev,n_ens,nv3d))
  ALLOCATE(anal2d(nij1,n_ens,nv2d))
!
  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(INITIALIZE):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! Observations
!-----------------------------------------------------------------------
  !
  ! CONVENTIONAL OBS
  !
  CALL set_letkf_obs

  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(READ_OBS):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! First guess ensemble
!-----------------------------------------------------------------------
  !
  ! READ GUES
  !
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  WRITE(guesf(3:4),'(I2.2)') nbslot
  CALL read_ens_mpi(guesf,n_ens,gues3d,gues2d)
  !
  ! WRITE ENS MEAN and SPRD
  !
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  CALL write_ensmspr_mpi('gues',n_ens,gues3d,gues2d)

  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(READ_GUES):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! Data Assimilation
!-----------------------------------------------------------------------
  !
  ! Additive covariance inflation
  !
  if (add_infl) then
      CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
      call read_ens_mpi('adin',n_ens,adin3d,adin2d)
    
      ! Calculate mean of additive perturbations
      adin3dmean = sum(adin3d, 3)/real(n_ens)
      adin2dmean = sum(adin2d, 2)/real(n_ens)
    
      ! Remove mean from perturbations
      do j = 1,n_ens
        adin3d(:,:,j,:) = adin3d(:,:,j,:) - adin3dmean 
        adin2d(:,j,:) = adin2d(:,j,:) - adin2dmean 
      end do
    
      print *, 'ADDITIVE ', adin2d(:10,1,1)
    
      gues3d = gues3d + adin3d
      gues2d = gues2d + adin2d
  end if

  !
  ! LETKF
  !
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  CALL das_letkf(gues3d,gues2d,anal3d,anal2d)

  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(DAS_LETKF):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! Analysis ensemble
!-----------------------------------------------------------------------
  !
  ! WRITE ANAL
  !
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  CALL write_ens_mpi('anal',n_ens,anal3d,anal2d)
  !
  ! WRITE ENS MEAN and SPRD
  !
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  CALL write_ensmspr_mpi('anal',n_ens,anal3d,anal2d)

  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(WRITE_ANAL):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! Monitor
!-----------------------------------------------------------------------
  CALL monit_mean('gues')
  CALL monit_mean('anal')

  CALL CPU_TIME(rtimer)
  WRITE(6,'(A,2F10.2)') '### TIMER(MONIT_MEAN):',rtimer,rtimer-rtimer00
  rtimer00=rtimer
!-----------------------------------------------------------------------
! Finalize
!-----------------------------------------------------------------------
  CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
  CALL finalize_mpi

  STOP
END PROGRAM letkf
