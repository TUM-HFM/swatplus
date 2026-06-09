      subroutine res_read_hyd
      
      use basin_module
      use input_file_module
      use maximum_data_module
      use reservoir_data_module
      
      implicit none     
         
      character (len=80) :: titldum = ""  !             |title of file
      character (len=80) :: header = "" !             |header of file
      character (len=500) :: line = ""  !             |buffer for backward-compatible read
      integer :: eof = 0                !             |end of file
      integer :: ios = 0                !             |internal read status
      integer :: imax = 0               !             |determine max number for array (imax) and total number in file
      logical :: i_exist                !none         |check to determine if file exists
      integer :: ires = 0               !none         |counter
      
      eof = 0
      imax = 0

      inquire (file=in_res%hyd_res, exist=i_exist)
      if (.not. i_exist .or. in_res%hyd_res == "null") then
        allocate (res_hyddb(0:0))
      else   
      do
       open (105,file=in_res%hyd_res)
       read (105,*,iostat=eof) titldum
       if (eof < 0) exit
       read (105,*,iostat=eof) header
       if (eof < 0) exit
        do while (eof == 0)
          read (105,*,iostat=eof) titldum
          if (eof < 0) exit
          imax = imax + 1
        end do
        
      db_mx%res_hyd = imax
      
      allocate (res_hyddb(0:imax))
      rewind (105)
      read (105,*,iostat=eof) titldum
      if (eof < 0) exit
      read (105,*,iostat=eof) header
      if (eof < 0) exit
      
       do ires = 1, imax
         
         !read (105,*,iostat=eof) titldum
         !backspace (105)
         read (105,'(A)',iostat=eof) line
         if (eof < 0) exit
         !! tier 1: 15-field new format (all fields)
         read (line,*,iostat=ios) res_hyddb(ires)
         if (ios /= 0) then
           !! tier 2: 13-field format (no area_type, no area_min)
           read (line,*,iostat=ios) res_hyddb(ires)%name,                    &
             res_hyddb(ires)%iyres,  res_hyddb(ires)%mores,                  &
             res_hyddb(ires)%psa,    res_hyddb(ires)%pvol,                   &
             res_hyddb(ires)%esa,    res_hyddb(ires)%evol,                   &
             res_hyddb(ires)%k,      res_hyddb(ires)%evrsv,                  &
             res_hyddb(ires)%br1,    res_hyddb(ires)%br2,                    &
             res_hyddb(ires)%lag_up, res_hyddb(ires)%lag_down
           res_hyddb(ires)%area_type = 0
           res_hyddb(ires)%area_min  = 0.
         end if
         if (ios /= 0) then
           !! tier 3: 11-field old format (no lag, no area_type, no area_min)
           read (line,*,iostat=ios) res_hyddb(ires)%name,                    &
             res_hyddb(ires)%iyres,  res_hyddb(ires)%mores,                  &
             res_hyddb(ires)%psa,    res_hyddb(ires)%pvol,                   &
             res_hyddb(ires)%esa,    res_hyddb(ires)%evol,                   &
             res_hyddb(ires)%k,      res_hyddb(ires)%evrsv,                  &
             res_hyddb(ires)%br1,    res_hyddb(ires)%br2
           res_hyddb(ires)%lag_up   = 0.
           res_hyddb(ires)%lag_down = 0.
           res_hyddb(ires)%area_type = 0
           res_hyddb(ires)%area_min  = 0.
         end if

        if (res_hyddb(ires)%pvol + res_hyddb(ires)%evol > 0.) then
          if(res_hyddb(ires)%pvol <= 0) res_hyddb(ires)%pvol = 0.9 * res_hyddb(ires)%evol
        else
          if (res_hyddb(ires)%pvol <= 0) res_hyddb(ires)%pvol = 60000.0
        end if
        if (res_hyddb(ires)%evol <= 0.0) res_hyddb(ires)%evol = 1.11 * res_hyddb(ires)%pvol
        if (res_hyddb(ires)%psa <= 0.0) res_hyddb(ires)%psa = 0.08 * res_hyddb(ires)%pvol
        if (res_hyddb(ires)%esa <= 0.0) res_hyddb(ires)%esa = 1.5 * res_hyddb(ires)%psa
        if (res_hyddb(ires)%evrsv <= 0.) res_hyddb(ires)%evrsv = 0.6

       end do
       close (105)
      exit
      enddo
      endif
  
      return
      end subroutine res_read_hyd