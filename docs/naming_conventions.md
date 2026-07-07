# Naming Conventions

Conventions used across the `data_warehouse` database, so that new tables,
views, and columns stay consistent with the existing ones.

## Schemas

| Schema   | Purpose                                                        |
|----------|------------------------------------------------------------------|
| `bronze` | Raw data, as ingested from source systems, no transformation.  |
| `silver` | Cleansed, standardized, and validated data.                     |
| `gold`   | Business-ready, dimensionally-modeled data for reporting.       |

## Tables

- **Bronze and Silver:** table names mirror the source system and source
  object, in `snake_case`, prefixed with the originating system:
  - `crm_*` — tables sourced from the CRM system (e.g. `crm_cust_info`,
    `crm_prd_info`, `crm_sales_details`).
  - `erp_*` — tables sourced from the ERP system (e.g. `erp_CUST_AZ12`,
    `erp_LOC_A101`, `erp_PX_CAT_G1V2`). The trailing segment (`AZ12`,
    `A101`, `G1V2`) is carried over verbatim from the source system's own
    file/table identifiers.
- **Gold:** views are prefixed by their role in the dimensional model:
  - `dim_*` — dimension views (e.g. `dim_customers`, `dim_products`).
  - `fact_*` — fact views (e.g. `fact_sales`).

## Columns

- **Surrogate keys:** named `<entity>_key` (e.g. `customer_key`,
  `product_key`), generated via `ROW_NUMBER()` in the Gold layer views.
  These are the keys fact tables should join against — never the natural
  business keys.
- **Business/natural keys:** named `<entity>_id` or `<entity>_number`
  depending on the source system's own terminology (e.g. `customer_id`,
  `product_number`).
- **Dates:** suffixed `_dt` in Bronze/Silver (e.g. `prd_start_dt`,
  `sls_order_dt`), renamed to plain, readable names in Gold (e.g.
  `start_date`, `order_date`).
- **Warehouse metadata:** columns tracking load metadata are prefixed
  `dwh_` (e.g. `dwh_create_date`), keeping them clearly separate from
  source-system columns.
- **Standardized/derived values:** columns holding cleansed, human-readable
  values use plain descriptive names in Gold (e.g. `gender`,
  `marital_status`, `country`, `product_line`), even when the underlying
  Silver/Bronze column used a coded or abbreviated name.

## General Style

- SQL keywords are written in `UPPERCASE` (`SELECT`, `FROM`, `CASE WHEN`).
- Identifiers (schemas, tables, columns) are written in `snake_case`,
  except where a column name is inherited directly from a source system in
  a different case (e.g. ERP columns like `CID`, `GEN`, `CNTRY`), which are
  kept as-is through Bronze and Silver to make source lineage traceable.
- Every script that creates an object checks for its existence first and
  drops it before recreating, so scripts are safe to re-run during
  development.
