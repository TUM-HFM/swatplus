      subroutine sd_channel_rating_init

      use sd_channel_module
      use channel_velocity_module
      use maximum_data_module
      use hydrograph_module
      use basin_module

      implicit none

      integer :: i = 0                  !none         |counter
      integer :: i_dep = 0              !none         |counter

      real :: aa = 0.                 !none         |area/area=1 (used to calculate velocity with
                                      !             |Manning"s equation)
      real :: a = 0.                  !m^2          |cross-sectional area of channel
      real :: b = 0.                  !m            |bottom width of channel
      real :: d = 0.                  !m            |depth of flow
      real :: p = 0.                  !m            |wetting perimeter
      real :: chside = 0.             !none         |change in horizontal distance per unit
                                      !             |change in vertical distance on channel side
                                      !             |slopes; always set to 2 (slope=1/2)
      real :: fps = 0.                !none         |change in horizontal distance per unit
                                      !             |change in vertical distance on floodplain side
                                      !             |slopes; always set to 4 (slope=1/4)
      real :: rh = 0.                 !m            |hydraulic radius
      real :: qman                    !m^3/s or m/s |flow rate or flow velocity

      real :: dep = 0.                !             |
      real :: vel = 0.                !             |
      real :: celerity = 0.
      real :: msk1 = 0.    !units             |description
      real :: msk2 = 0.    !units             |description
      real :: detmax = 0.  !units             |description
      real :: xkm = 0.     !hr                |storage time constant for the reach
      real :: det = 0.     !hr                |time step
      real :: denom = 0.   !none              |variable to hold intermediate calculation
      real :: sumc = 0.    !none              |sum of Muskingum coefficients

      !! recomputes the rating curve, travel-time coefficients, and Muskingum
      !! routing coefficients from the current sd_ch(:) values (chn/chs/chl/chw/
      !! chd/chss) - must be called once during initialization and again after
      !! calibration (proc_cal) is applied, since these are the only downstream
      !! consumers of those calibratable channel geometry parameters
      do i = 1, sp_ob%chandeg

        !! guard against a calibrated chd/chss of ~0, which would divide by
        !! zero below - chs is guarded the same way at read time in
        !! sd_hydsed_init.f90, but chd/chss must be guarded here since they
        !! can be changed by calibration on every call to this subroutine
        if (sd_ch(i)%chd < 1.e-9) sd_ch(i)%chd = .000001
        if (sd_ch(i)%chss < 1.e-9) sd_ch(i)%chss = .000001

        !! compute travel time coefficients - delete when finished with flood plain
        aa = 1.
        b = 0.
        d = 0.
        chside = sd_ch(i)%chss
        fps = 4.
        b = sd_ch(i)%chw - 2. * sd_ch(i)%chd * chside

        !! check IF bottom width (b) is < 0
        if (b <= 0.) then
            b = .5 * sd_ch(i)%chw
            b = Max(0., b)
            chside = (sd_ch(i)%chw - b) / (2. * sd_ch(i)%chd)
        end if
        sd_ch_vel(i)%wid_btm = b
        sd_ch_vel(i)%dep_bf = sd_ch(i)%chd  !delete sd_ch_vel when finished
        !! compute travel time coefficients - delete when finished with flood plain

        !! compute rating curve
        call sd_rating_curve (i)

        !! set Muskingum parameters
        !! compute storage discharge for Muskingum at 0.1 and 1.0 times bankfull depth
      do i_dep = 1, 2
        if (i_dep == 1) dep = 0.1 * sd_ch(i)%chd
        if (i_dep == 2) dep = sd_ch(i)%chd
        !! c^2=a^2+b^2 - a=dep; a/b=slope; b^2=a^2/slope^2
        p = b + 2. * Sqrt(dep ** 2 * (1. + 1. / (sd_ch(i)%chss ** 2)))
        a = b * dep + dep / sd_ch(i)%chss
        rh = a / p
        vel = Qman(1., rh, sd_ch(i)%chn, sd_ch(i)%chs)
        celerity = vel * 5. / 3.
        if (i_dep == 1) then
          !! 0.1*bankfull storage discharge coef
          sd_ch(i)%stor_dis_01bf = sd_ch(i)%chl / (3.6 * celerity)
        else
          !! bankfull storage discharge coef
          sd_ch(i)%stor_dis_bf = sd_ch(i)%chl / (3.6 * celerity)
        end if
      end do

      !! Compute storage time constant for reach (msk_co1 + msk_co2 = 1.)
	  msk1 = bsn_prm%msk_co1 / (bsn_prm%msk_co1 + bsn_prm%msk_co2)
	  msk2 = bsn_prm%msk_co2 / (bsn_prm%msk_co1 + bsn_prm%msk_co2)
      xkm = sd_ch(i)%stor_dis_bf * msk1 + sd_ch(i)%stor_dis_01bf * msk2

      !! Muskingum numerical stability -Jaehak Jeong, 2011
      detmax = 2.* xkm * (1.- bsn_prm%msk_x)
      det = time%dtm / 60.      !hours
      sd_ch(i)%msk%substeps = 1

      !! Discretize time interval to meet the stability criterion
      if (det > detmax) then
        sd_ch(i)%msk%substeps = Int(det / detmax) + 1
      end if
      if (bsn_cc%rte == 0 .and. time%step <= 1) then
        sd_ch(i)%msk%substeps = 1
      end if
      sd_ch(i)%msk%nsteps = time%step * sd_ch(i)%msk%substeps

        !! intial inflow-outflow
        if (sd_ch(i)%msk%nsteps > 0) then
          sd_ch(i)%in1_vol = rcurv%flo_rate / (86400. / sd_ch(i)%msk%nsteps)
          sd_ch(i)%out1_vol = rcurv%flo_rate / (86400. / sd_ch(i)%msk%nsteps)
        end if

        !! compute coefficients
        det = det / sd_ch(i)%msk%substeps
        denom = 2. * xkm * (1. - bsn_prm%msk_x) + det
        sd_ch(i)%msk%c1 = (det - 2. * xkm * bsn_prm%msk_x) / denom
        sd_ch(i)%msk%c1 = Max(0., sd_ch(i)%msk%c1)
        sd_ch(i)%msk%c2 = (det + 2. * xkm * bsn_prm%msk_x) / denom
        sd_ch(i)%msk%c3 = (2. * xkm * (1. - bsn_prm%msk_x) - det) / denom
        !! c1+c2+c3 must equal 1
        sumc = sd_ch(i)%msk%c1 + sd_ch(i)%msk%c2 + sd_ch(i)%msk%c3
        sd_ch(i)%msk%c1 = sd_ch(i)%msk%c1 / sumc
        sd_ch(i)%msk%c2 = sd_ch(i)%msk%c2 / sumc
        sd_ch(i)%msk%c3 = sd_ch(i)%msk%c3 / sumc

      end do    !end of channel loop

      return
      end subroutine sd_channel_rating_init
