{{ config(
    materialized='table',
    indexes=[
      {'columns': ['category'], 'unique': true}
    ]
) }}

-- Category dimension, one row per spend category (14 rows).
--
-- Exists so that category-keyed marts can be filtered together. mart_segment_kpi and
-- mart_merchant_risk both carry a `category` column, but with no shared dimension a BI
-- tool cannot relate them - a category slicer would filter one visual and leave the
-- other showing totals. Both now point at this table instead.
--
-- Also the place where the channel split lives as a real attribute rather than something
-- every consumer has to re-derive from the category name suffix.

SELECT
    category,

    -- Display label. The channel is kept in the label rather than stripped: three base
    -- names (shopping, misc, grocery) exist in both an _net and a _pos variant, and their
    -- fraud rates differ sharply - shopping_net runs 1.06% against shopping_pos at 0.40%.
    -- A label of plain "Shopping" would silently merge the two in any chart grouped on it,
    -- so the suffix is translated instead of dropped. Tested for uniqueness.
    INITCAP(REPLACE(REPLACE(REPLACE(category, '_net', ''), '_pos', ''), '_', ' '))
        || CASE
             WHEN RIGHT(category, 4) = '_net' THEN ' (Online)'
             WHEN RIGHT(category, 4) = '_pos' THEN ' (In-person)'
             ELSE ''
           END                                  AS category_label,

    -- channel as a three-value attribute. 'Unknown' rather than a NULL or a silent
    -- default to in-person: the categories with no suffix genuinely do not say.
    CASE
        WHEN RIGHT(category, 4) = '_net' THEN 'Online'
        WHEN RIGHT(category, 4) = '_pos' THEN 'In-person'
        ELSE 'Unknown'
    END AS channel,

    CASE
        WHEN RIGHT(category, 4) = '_net' THEN TRUE
        WHEN RIGHT(category, 4) = '_pos' THEN FALSE
    END AS is_online,

    COUNT(*)                                      AS cnt_transactions,
    COUNT(*) FILTER (WHERE is_fraud)              AS fraud_cnt,
    COALESCE(SUM(amt) FILTER (WHERE is_fraud), 0) AS fraud_amount,
    ROUND(COUNT(*) FILTER (WHERE is_fraud) * 1.0 / NULLIF(COUNT(*), 0), 5) AS fraud_rate

FROM {{ ref('stg_transactions') }}
GROUP BY category
