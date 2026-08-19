# fraud_project (dbt)

Transformation layer for the credit-card fraud project. Takes the raw Sparkov/Kaggle
transaction dump loaded into Postgres and turns it into a documented star schema plus a
set of aggregate marts that the notebooks and the BI dashboard read from.

## Layers

```
source: public.raw_transactions   (loaded by ../sql/create_raw.sql)
   |
   +-- staging/     public_staging   typing, cleaning, split labelling
   |
   +-- dimensions/  public_core      dim_customers, dim_merchants, dim_date, dim_category
   +-- facts/       public_core      fact_transactions
   |
   +-- marts/       public_marts     8 marts: KPIs, risk scoring, features
```

| Layer | Schema | Models |
|---|---|---|
| staging | `public_staging` | `stg_transactions` |
| core | `public_core` | `dim_customers`, `dim_merchants`, `dim_date`, `dim_category`, `fact_transactions` |
| marts | `public_marts` | `mart_daily_kpi`, `mart_hourly_kpi`, `mart_segment_kpi`, `mart_merchant_risk`, `mart_card_profile`, `mart_card_velocity`, `mart_fraud_sessions`, `mart_transactions_enriched` |

Everything is materialized as a table. The source is 2.77M rows and the marts get read
repeatedly by notebooks and Power BI, so paying the build cost once beats re-running the
aggregations on every query.

## Which mart to use for what

| Mart | Grain | Use it for |
|---|---|---|
| `mart_daily_kpi` | day | time series, dashboard overview page |
| `mart_hourly_kpi` | day-of-week x hour | time-of-day risk pattern, heatmap |
| `mart_segment_kpi` | month x gender x age x category | segment analysis, dashboard segment page |
| `mart_merchant_risk` | merchant | merchant risk ranking, scatter plots |
| `mart_card_profile` | card | per-card behaviour, post-fraud activity |
| `mart_card_velocity` | transaction | point-in-time-safe model features |
| `mart_fraud_sessions` | fraud burst | attack episodes rather than isolated rows |
| `mart_transactions_enriched` | transaction | the table `preprocessing.ipynb` reads |

Aggregate marts are small (a few thousand rows) and safe to import into a BI tool.
`mart_transactions_enriched` and `mart_card_velocity` are 2.77M rows each - read those from
Python, not from Power BI.

## Running it

Requires the Postgres container from `../docker-compose.yml` to be up, and a
`fraud_project` profile in `~/.dbt/profiles.yml` pointing at `localhost:5433`.

```bash
docker compose up -d
```

```bash
dbt run
```

```bash
dbt test
```

```bash
dbt docs generate && dbt docs serve
```

`mart_card_velocity` is by far the slowest model - `cnt_distinct_merchants_24h` uses a
correlated subquery evaluated once per row. Expect a full `dbt run` to be dominated by it.

## Conventions worth knowing

**Two different day-of-week encodings exist on purpose.**
`fact_transactions.day_of_week` uses Postgres `DOW` (0=Sunday .. 6=Saturday) because it is
a frozen model feature - see `data/processed/features.json`. `dim_date.day_of_week` uses
ISO (1=Monday .. 7=Sunday). They must not be joined to each other; `dim_date.day_of_week_pg`
carries the DOW convention for that purpose, and both tables expose `day_name` for display.

**Category is a shared dimension.**
`mart_segment_kpi`, `mart_merchant_risk` and `dim_merchants` all key on `category` and all
relate to `dim_category`. Filter through the dimension, not through one mart's own column -
a slicer taken off a mart only filters that mart and silently leaves other visuals showing
totals.

**Measures belong to the table whose grain they describe.**
A fraud-rate measure written against `mart_daily_kpi` cannot be sliced by category, gender
or age: those columns live in `mart_segment_kpi`, and the two marts only meet at the date
dimension. Each mart needs its own rate measure built from its own counts.

**Ratio columns are 0-1, and must not be averaged.**
`fraud_percentage`, `fraud_share`, `fraud_rate` are ratios stored at the grain of their own
table. Averaging them across rows gives a wrong answer - re-derive from the underlying
counts at whatever grain is being displayed.

**Low-volume gates.**
`mart_merchant_risk.has_enough_volume` (200+ transactions) and
`mart_hourly_kpi.has_enough_volume` (100+ transactions) exist so that a single incident in
a thin slice does not top a fraud-rate ranking. Apply them before ranking.

**`stg_transactions.is_online` is deliberately NULL for some categories.**
It is inferred from the `_net` / `_pos` category suffix; categories with neither suffix
(entertainment, food_dining, health_fitness, home, kids_pets, personal_care, travel) have
an unknown channel and are left NULL rather than defaulted to in-person.

**The split is chronological, not random.**
`split_period` labels rows train (<= 2020-12-31), valid (<= 2021-06-30), test (after), so
no future information leaks into training.

## Tests

All generic dbt tests, no packages required - `dbt test` works without `dbt deps`.
Coverage: primary keys on every model, referential integrity from the fact and the marts
back to the dimensions, and `accepted_values` on the categorical columns whose domains the
downstream code depends on (`split_period`, `age_bucket`, `gender`, `amt_bucket`, both
day-of-week encodings).

Adding `dbt_utils` would allow composite-key uniqueness tests on the marts whose grain
spans several columns (`mart_hourly_kpi`, `mart_segment_kpi`, `mart_fraud_sessions`) -
those currently have `not_null` on the key parts but no uniqueness guarantee.
