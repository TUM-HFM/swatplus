      subroutine sd_channel_aqu_seep_init

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine sets the aquifer receiving the seepage of each channel:
!!    the aquifer that receives recharge (rhg) from the routing unit or hru
!!    draining into the channel - largest contributing area if there are several

      use hydrograph_module
      use sd_channel_module

      implicit none

      integer :: icha = 0              !none          |channel number
      integer :: iob = 0              !none          |channel object number
      integer :: in = 0               !none          |counter
      integer :: iob_in = 0           !none          |incoming object number
      integer :: iout = 0             !none          |counter
      real :: area_max = 0.           !ha            |largest contributing area found

      allocate (aqu_cha_seep(sp_ob%aqu))
      aqu_cha_seep = hz

      do icha = 1, sp_ob%chandeg
        iob = sp_ob1%chandeg + icha - 1
        area_max = 0.
        do in = 1, ob(iob)%rcv_tot
          iob_in = ob(iob)%obj_in(in)
          if (ob(iob_in)%typ == "ru" .or. ob(iob_in)%typ == "hru") then
            do iout = 1, ob(iob_in)%src_tot
              if (ob(iob_in)%obtyp_out(iout) == "aqu" .and. ob(iob_in)%htyp_out(iout) == "rhg") then
                if (ob(iob_in)%area_ha > area_max) then
                  area_max = ob(iob_in)%area_ha
                  sd_ch(icha)%aqu_seep = ob(iob_in)%obtypno_out(iout)
                end if
              end if
            end do
          end if
        end do
        if (sd_ch(icha)%aqu_seep == 0) then
          write (9001,*) "channel ", icha, ob(iob)%name, " - no aquifer found for channel seepage (seepage leaves the model)"
        end if
      end do

      return
      end subroutine sd_channel_aqu_seep_init
