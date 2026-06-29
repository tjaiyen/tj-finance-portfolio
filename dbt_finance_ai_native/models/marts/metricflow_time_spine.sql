-- Daily date spine required by the MetricFlow semantic layer.
-- Built with dbt_utils.date_spine so it is adapter-portable (DuckDB and Databricks).

{{ config(materialized='table') }}

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2026-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}

)

select cast(date_day as date) as date_day
from spine
