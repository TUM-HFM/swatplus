      subroutine res_area_calc (vol, rob, area_ha)

      use reservoir_module

      implicit none

      real,            intent(in)  :: vol    !m^3    |current reservoir storage
      type(reservoir), intent(in)  :: rob    !       |reservoir object parameters
      real,            intent(out) :: area_ha !ha    |computed surface area

      if (vol <= 0.) then
        area_ha = 0.
        return
      end if

      if (rob%area_type == 1) then
        !! linear: A = max(area_min, br1 + br2*V)
        area_ha = max(rob%area_min, rob%br1 + rob%br2 * vol)
      else
        !! power law: A = max(area_min, br1 * V^br2)
        area_ha = max(rob%area_min, rob%br1 * vol ** rob%br2)
      end if

      return
      end subroutine res_area_calc
