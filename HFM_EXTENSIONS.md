# HFM SWAT+ Extensions — User Guide

This document describes features added or corrected in the HFM fork of SWAT+
that are not part of the official release. It covers changes to input file
formats and new decision table options.

---

## 1. `hydrology.res` — New Columns

Four optional columns have been added after `shp_co2`. Old 11-column files
are still read correctly — new fields default to 0.

### Full column layout

```
name  yr_op  mon_op  area_ps  vol_ps  area_es  vol_es  k  evap_co  shp_co1  shp_co2  lag_up  lag_down  area_type  area_min
```

### New columns

| Column | Default | Description |
|---|---|---|
| `lag_up` | 0.0 | Release smoothing rate when outflow is **increasing**. `0` = no smoothing. |
| `lag_down` | 0.0 | Release smoothing rate when outflow is **decreasing**. `0` = no smoothing. |
| `area_type` | 0 | Area–volume formula: `0` = power law, `1` = linear (see below). |
| `area_min` | 0.0 | Minimum surface area (ha). Applied as a floor — useful for dead-pool area. |

### `lag_up` / `lag_down`

Each day the computed release is smoothed with:

```
release = computed × exp(−lag) + previous × (1 − exp(−lag))
```

`lag_up` applies when the release is increasing; `lag_down` when it is
decreasing. Higher values produce more smoothing and slower response. This
prevents sharp jumps when a decision table condition flips (e.g. at a month
boundary or when a volume threshold is crossed).

### `area_type` and `area_min`

Selects how surface area is computed from storage volume:

| `area_type` | Formula | When to use |
|---|---|---|
| `0` (default) | `A = max(area_min, shp_co1 × V ^ shp_co2)` | Natural lakes and reservoirs with concave hypsometry |
| `1` | `A = max(area_min, shp_co1 + shp_co2 × V)` | Reservoirs with near-linear area–volume relationship |

`area_min` sets a dead-pool surface area that is used even when storage is near
zero. Set to `0` if no dead pool exists.

### Auto-computation of `shp_co1` / `shp_co2`

When both `shp_co1` and `shp_co2` are `0` in the input file, the model derives
them automatically from the principal and emergency spillway geometry
(`area_ps`, `vol_ps`, `area_es`, `vol_es`):

- `area_type = 0`: log-log regression → `shp_co2 = Δlog(area) / Δlog(vol)`,
  `shp_co1 = area_es / vol_es ^ shp_co2`. Falls back to `shp_co2 = 0.9` if
  the geometry is degenerate.
- `area_type = 1`: linear fit → `shp_co2 = (area_es − area_ps) / (vol_es − vol_ps)`,
  `shp_co1 = area_ps − shp_co2 × vol_ps`.

To supply your own coefficients, set `shp_co1` and `shp_co2` to non-zero
values — auto-computation is then skipped.

### Example row (new format)

```
name     yr_op  mon_op  area_ps   vol_ps    area_es   vol_es    k  evap_co  shp_co1  shp_co2  lag_up  lag_down  area_type  area_min
res_inn      1       1  450.000  4500.000  520.000  5200.000  0.0    0.6     0.0      0.0      0.5     1.0          0        5.0
```

This reservoir will auto-compute `shp_co1`/`shp_co2` (power law), apply
exponential smoothing (`lag_up = 0.5`, `lag_down = 1.0`), and never let
surface area drop below 5 ha.

---

## 2. `res_demand` Action in `flo_con.dtl`

`res_demand` sets the daily water demand from a reservoir in the water
allocation framework. Use it as the `act_typ` in a flow-control decision table
(`flo_con.dtl`) when a reservoir is a demand object in `water_allocation.wro`.

The `obj_num` field identifies the reservoir (matches the `id` in
`reservoir.con`). Set `obj_num = 0` to apply to the reservoir that owns the
decision table.

### Options

| `option` | `const` | `const2` | `fp` | Demand computed |
|---|---|---|---|---|
| `storage` | target fraction | — | `pvol` / `evol` | `max(0, const × ref_vol − current_storage)` |
| `release` | base fraction | — | `pvol` / `evol` | `max(0, current_storage − const × ref_vol)` |
| `release_days` | base fraction | drawdown days | `pvol` / `evol` / `null` | `max(0, (current_storage − const × ref_vol) / const2)` |
| `rate` | flow rate (m³/s) | — | — | `const × 86400` m³/day |

- **`storage`** — demand is the deficit needed to fill the reservoir to
  `const` × principal (`pvol`) or emergency (`evol`) volume. Use for pump-fill
  operations.
- **`release`** — demand is the volume held above `const` × reference volume.
  Use for routing excess storage through the water allocation framework.
- **`release_days`** — same as `release` but spread evenly over `const2` days
  (drawdown schedule). `fp = null` draws down total storage with no base.
- **`rate`** — fixed daily demand regardless of reservoir state. Use for
  mandatory minimum releases or constant withdrawals.

### Example decision table action rows

```
act_typ      obj   obj_num  name          option         const   const2  fp    outcome
res_demand  null         1  fill_res      storage          1.0      0.0  pvol  y
res_demand  null         1  release_exc   release          1.0      0.0  pvol  y
res_demand  null         1  drawdown      release_days     1.0     30.0  pvol  y
res_demand  null         1  min_outflow   rate             2.5      0.0  null  y
```

---

## 3. Reservoir Release Options in `res_rel.dtl`

Two new `option` values are available in reservoir release decision tables
(`res_rel.dtl`). They extend the existing `inflo_frac` and `inflo_rate` options
to include water received via the water allocation framework on the same day.

| `option` | Based on | Release computed |
|---|---|---|
| `inflo_frac_total` | `inflo_frac` | `(natural_inflow + wallo_inflow) × const` |
| `inflo_rate_total` | `inflo_rate` | `max(natural_inflow + wallo_inflow + const2×86400, const×86400)` |

`wallo_inflow` is the volume transferred to this reservoir by the water
allocation framework on the current day. Use the `_total` variants when the
reservoir receives allocated water and the release rule should respond to the
combined inflow.

`const` and `const2` carry the same meaning as in the base variants:
- `const` — minimum release (m³/s) or pass-through fraction
- `const2` — adjustment to inflow before applying the min (m³/s, signed)
