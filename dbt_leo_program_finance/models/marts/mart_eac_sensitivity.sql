-- EAC sensitivity (tornado-style): sweeps CPI and SPI independently at +/-10%/20%,
-- one driver at a time with the other held at its actual value, and recomputes
-- eac_composite from mart_evm_rollup's own constants -- pure formula recomputation,
-- no new inputs. Answers "how much does the estimate-at-completion move if cost or
-- schedule performance shifts" -- the classic FP&A stress-the-model deliverable this
-- dashboard's EVM section didn't have. Base case (swing_pct = 0) reproduces
-- mart_evm_rollup.eac_composite exactly by construction -- a built-in check that the
-- sweep formula matches the mart it's derived from.
with base as (
    select bac, ac, ev, cpi, spi from {{ ref('mart_evm_rollup') }}
),

swings (swing_pct) as (
    values (-0.20), (-0.10), (0.0), (0.10), (0.20)
),

cpi_sweep as (
    select
        'CPI' as driver,
        s.swing_pct,
        round(b.cpi * (1 + s.swing_pct), 4) as swung_value,
        round(b.ac + (b.bac - b.ev) / (b.cpi * (1 + s.swing_pct) * b.spi), 0) as eac_composite_usd
    from base b cross join swings s
),

spi_sweep as (
    select
        'SPI' as driver,
        s.swing_pct,
        round(b.spi * (1 + s.swing_pct), 4) as swung_value,
        round(b.ac + (b.bac - b.ev) / (b.cpi * b.spi * (1 + s.swing_pct)), 0) as eac_composite_usd
    from base b cross join swings s
),

combined as (
    select * from cpi_sweep
    union all
    select * from spi_sweep
),

base_eac as (
    select round(ac + (bac - ev) / (cpi * spi), 0) as eac_composite_base_usd
    from base
)

select
    c.driver,
    c.swing_pct,
    c.swung_value,
    c.eac_composite_usd,
    be.eac_composite_base_usd,
    c.eac_composite_usd - be.eac_composite_base_usd as delta_from_base_usd,
    true as is_illustrative,
    'Single-variable sensitivity: one driver (CPI or SPI) swung +/-10%/20% at a time, the other held at its actual value, recomputing eac_composite from mart_evm_rollup''s own bac/ac/ev/cpi/spi -- no new inputs. Base case (swing_pct = 0) reproduces mart_evm_rollup.eac_composite exactly by construction.' as notes
from combined c
cross join base_eac be
order by driver, swing_pct
