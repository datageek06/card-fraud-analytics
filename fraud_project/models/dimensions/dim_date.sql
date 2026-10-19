{{ config(
    materialized='table',
    indexes=[
      {'columns': ['date'], 'unique': true}
    ]
) }}

WITH bounds AS (
    SELECT
        MIN(trans_date)::timestamp AS date_min,
        MAX(trans_date)::timestamp AS date_max
    FROM {{ ref('stg_transactions') }}
)

SELECT
    series::date AS date,
    EXTRACT(ISODOW FROM series)::int AS day_of_week,
    EXTRACT(DOW FROM series)::int AS day_of_week_pg,
    TRIM(TO_CHAR(series, 'Day')) AS day_name,
    TRIM(TO_CHAR(series, 'Month')) AS month_name,
    EXTRACT(YEAR FROM series)::int AS year,
    EXTRACT(MONTH FROM series)::int AS month,
    EXTRACT(QUARTER FROM series)::int AS quarter,
    TO_CHAR(series, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', series)::date AS month_start,
    EXTRACT(WEEK FROM series)::int AS week_number,
    CASE
        WHEN EXTRACT(ISODOW FROM series) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM bounds b,
    generate_series(b.date_min, b.date_max, '1 day'::interval) AS series
