      subroutine sq_canopyint

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine computes canopy interception of rainfall
!!    used for methods other than curve number

!!    ~ ~ ~ INCOMING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    blai(:)     |none          |maximum (potential) leaf area index
!!    canmx(:)    |mm H2O        |maximum canopy storage
!!    canstor(:)  |mm H2O        |amount of water held in canopy storage
!!    wst(:)%weat%ts(:) |mm H2O        |precipitation in time step for HRU
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ OUTGOING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    canstor(:)  |mm H2O        |amount of water held in canopy storage
!!    wst(:)%weat%ts(:) |mm H2O        |precipitation reaching soil surface in
!!                               |time step
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    ~ ~ ~ ~ ~ ~ END SPECIFICATIONS ~ ~ ~ ~ ~ ~

      use basin_module
      use time_module
      use climate_module, only : w
      use hru_module, only : hru, canstor,ihru, precip_eff
      use plant_module
      
      implicit none

      real :: xx = 0.            !mm H2O        |precipitation prior to canopy interception 
      integer :: j = 0           !none          |HRU number
      integer :: ii = 0          !none          |counter
      real :: canmxl = 0.        !mm H2O        |maximum canopy storage at current day's leaf
                                 !              |area
      real :: canstori = 0.      !mm H2O        |initial canopy storage water content 
      !real :: precip_eff        !mm            |daily effective precip for runoff calculations = precipday + ls_overq + snomlt - canstor
                                 !     |precip_eff = precipday + ls_overq - snofall + snomlt - canstor
      
      j = ihru

      if (pcom(j)%lai_sum < 0.001 .or. pcom(j)%laimx_sum < 0.001) return

      if (time%step > 1) then
          canstori = canstor(j)
          canmxl = hru(j)%hyd%canmx * pcom(j)%lai_sum / pcom(j)%laimx_sum
          do ii = 1, time%step
            xx = w%ts(ii)
            w%ts(ii) = w%ts(ii) - (canmxl - canstor(j))

            if (w%ts(ii) < 0.) then
              canstor(j) = canstor(j) + xx
              w%ts(ii) = 0.
            else
              canstor(j) = canmxl
            endif
          end do
          !! intercepted water is already removed from w%ts above - remove it from precip_eff for infiltration
          precip_eff = precip_eff - (canstor(j) - canstori)
          precip_eff = Max(0., precip_eff)

        else
          canmxl = hru(j)%hyd%canmx * pcom(j)%lai_sum / pcom(j)%laimx_sum
          !! check if precip_eff is less than remaining canopy storage
          if (precip_eff < canmxl - canstor(j)) then
            canstor(j) = canstor(j) + precip_eff
            precip_eff = 0.
          else
            precip_eff = precip_eff - (canmxl - canstor(j))
            canstor(j) = canmxl
          endif
       end if

      return
      end subroutine sq_canopyint