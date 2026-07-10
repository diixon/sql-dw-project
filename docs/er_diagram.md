# 📊 Entity Relationship Diagram (ERD) & Lineage

This document visualizes the structural schemas, inter-table constraints, and end-to-end data pipelines across all three architectural layers of the data warehouse.

---

## 🟡 Gold Layer: Star Schema (Reporting)

The Gold layer transforms your data assets into a highly optimized, consumer-ready dimensional star schema composed of unified dimensions and a central transaction fact view.

```mermaid
erDiagram
    "gold.dim_customers" {
        bigint customer_key PK
        int customer_id
        nvarchar customer_number
        nvarchar first_name
        nvarchar last_name
        nvarchar country
        nvarchar marital_status
        nvarchar gender
        date birthdate
        date create_date
    }

    "gold.dim_products" {
        bigint product_key PK
        int product_id
        nvarchar product_number
        nvarchar product_name
        nvarchar category_id
        nvarchar category
        nvarchar subcategory
        nvarchar maintenance
        int cost
        nvarchar product_line
        datetime start_date
    }

    "gold.fact_sales" {
        nvarchar order_number
        bigint product_key FK
        bigint customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales_amount
        int quantity
        int price
    }

    "gold.dim_customers" ||--o{ "gold.fact_sales" : "customer_key"
    "gold.dim_products" ||--o{ "gold.fact_sales" : "product_key"

```

### Relationships

| From Table | To Table | Type | Join Constraint Key |
| --- | --- | --- | --- |
| `gold.fact_sales` | `gold.dim_customers` | Many-to-One ($\infty \rightarrow 1$) | `customer_key` |
| `gold.fact_sales` | `gold.dim_products` | Many-to-One ($\infty \rightarrow 1$) | `product_key` |

---

## ⚪ Silver Layer: Cleansed Tables

The Silver layer acts as the standardization zone. Operational systems originating from different source landscapes (CRM and ERP) are cleanly separated, normalized, and mapped out via implicit lookup mappings.

```mermaid
erDiagram
    "silver.crm_cust_info" {
        int cst_id PK
        nvarchar cst_key UK
        nvarchar cst_firstname
        nvarchar cst_lastname
        nvarchar cst_marital_status
        nvarchar cst_gndr
        date cst_create_date
        datetime2 dwh_create_date
    }

    "silver.crm_prd_info" {
        int prd_id PK
        nvarchar cat_id
        nvarchar prd_key UK
        nvarchar prd_nm
        int prd_cost
        nvarchar prd_line
        datetime prd_start_dt
        datetime prd_end_dt
        datetime2 dwh_create_date
    }

    "silver.crm_sales_details" {
        nvarchar sls_ord_num
        nvarchar sls_prd_key FK
        int sls_cust_id FK
        date sls_order_dt
        date sls_ship_dt
        date sls_due_dt
        int sls_sales
        int sls_quantity
        int sls_price
        datetime2 dwh_create_date
    }

    "silver.erp_CUST_AZ12" {
        nvarchar CID UK
        date BDATE
        nvarchar GEN
        datetime2 dwh_create_date
    }

    "silver.erp_LOC_A101" {
        nvarchar CID UK
        nvarchar CNTRY
        datetime2 dwh_create_date
    }

    "silver.erp_PX_CAT_G1V2" {
        nvarchar ID PK
        nvarchar CAT
        nvarchar SUBCAT
        nvarchar MAINTENANCE
        datetime2 dwh_create_date
    }

    "silver.crm_cust_info" ||--o{ "silver.crm_sales_details" : "cst_id = sls_cust_id"
    "silver.crm_prd_info" ||--o{ "silver.crm_sales_details" : "prd_key = sls_prd_key"
    "silver.crm_cust_info" ||--o| "silver.erp_CUST_AZ12" : "cst_key = CID"
    "silver.crm_cust_info" ||--o| "silver.erp_LOC_A101" : "cst_key = CID"
    "silver.crm_prd_info" ||--o| "silver.erp_PX_CAT_G1V2" : "cat_id = ID"

```

### Relationships

| From Table | To Table | Type | Source Target Join Logic |
| --- | --- | --- | --- |
| `silver.crm_sales_details` | `silver.crm_cust_info` | Many-to-One | `sls_cust_id` $\rightarrow$ `cst_id` |
| `silver.crm_sales_details` | `silver.crm_prd_info` | Many-to-One | `sls_prd_key` $\rightarrow$ `prd_key` |
| `silver.crm_cust_info` | `silver.erp_CUST_AZ12` | One-to-Zero/One | `cst_key` $\rightarrow$ `CID` |
| `silver.crm_cust_info` | `silver.erp_LOC_A101` | One-to-Zero/One | `cst_key` $\rightarrow$ `CID` |
| `silver.crm_prd_info` | `silver.erp_PX_CAT_G1V2` | Many-to-One | `cat_id` $\rightarrow$ `ID` |

---

## 🟤 Bronze Layer: Raw Staging Tables

The Bronze layer ingests unstructured and raw transactional history directly from flat file systems. **No key constraints are actively enforced at this layer.** Table cross-references are purely structural and left intentionally decoupled until downstream cleaning.

```mermaid
erDiagram
    "bronze.crm_cust_info" {
        int cst_id
        nvarchar cst_key
        nvarchar cst_firstname
        nvarchar cst_lastname
        nvarchar cst_marital_status
        nvarchar cst_gndr
        date cst_create_date
    }

    "bronze.crm_prd_info" {
        int prd_id
        nvarchar prd_key
        nvarchar prd_nm
        int prd_cost
        nvarchar prd_line
        datetime prd_start_dt
        datetime prd_end_dt
    }

    "bronze.crm_sales_details" {
        nvarchar sls_ord_num
        nvarchar sls_prd_key
        int sls_cust_id
        int sls_order_dt
        int sls_ship_dt
        int sls_due_dt
        int sls_sales
        int sls_quantity
        int sls_price
    }

    "bronze.erp_CUST_AZ12" {
        nvarchar CID
        date BDATE
        nvarchar GEN
    }

    "bronze.erp_LOC_A101" {
        nvarchar CID
        nvarchar CNTRY
    }

    "bronze.erp_PX_CAT_G1V2" {
        nvarchar ID
        nvarchar CAT
        nvarchar SUBCAT
        nvarchar MAINTENANCE
    }

```

> ⚠️ **Architecture Note:** Primary keys, foreign references, and semantic uniqueness do not exist inside the Bronze layer. Structural cleaning anomalies, math inaccuracies, whitespace adjustments, and invalid timelines are audited and managed during the **Bronze $\rightarrow$ Silver** stored procedure transitions.

---

## 🗺️ Complete Pipeline Data Lineage

This node map visualizes the sequential processing flow from raw operational system flat storage down to final business-intelligence ready entity definitions.

```mermaid
flowchart TD
    %% Source Definitions
    subgraph Files ["📂 CSV File Storage"]
        C_Cust["cust_info.csv"]
        C_Prd["prd_info.csv"]
        C_Sls["sales_details.csv"]
        E_Cust["CUST_AZ12.csv"]
        E_Loc["LOC_A101.csv"]
        E_Cat["PX_CAT_G1V2.csv"]
    end

    %% Bronze Definitions
    subgraph Bronze ["🟤 Bronze Schema (Raw Staging)"]
        B_CCust["bronze.crm_cust_info"]
        B_CPrd["bronze.crm_prd_info"]
        B_CSls["bronze.crm_sales_details"]
        B_ECust["bronze.erp_CUST_AZ12"]
        B_ELoc["bronze.erp_LOC_A101"]
        B_ECat["bronze.erp_PX_CAT_G1V2"]
    end

    %% Silver Definitions
    subgraph Silver ["⚪ Silver Schema (Cleansed & Mapped)"]
        S_CCust["silver.crm_cust_info"]
        S_CPrd["silver.crm_prd_info"]
        S_CSls["silver.crm_sales_details"]
        S_ECust["silver.erp_CUST_AZ12"]
        S_ELoc["silver.erp_LOC_A101"]
        S_ECat["silver.erp_PX_CAT_G1V2"]
    end

    %% Gold Definitions
    subgraph Gold ["🟡 Gold Schema (Star Reporting Layer)"]
        G_DimCust["gold.dim_customers"]
        G_DimPrd["gold.dim_products"]
        G_FactSales["gold.fact_sales"]
    end

    %% Mapping Connections
    C_Cust --> B_CCust
    C_Prd  --> B_CPrd
    C_Sls  --> B_CSls
    E_Cust --> B_ECust
    E_Loc  --> B_ELoc
    E_Cat  --> B_ECat

    B_CCust --> S_CCust
    B_CPrd  --> S_CPrd
    B_CSls  --> S_CSls
    B_ECust --> S_ECust
    B_ELoc  --> S_ELoc
    B_ECat  --> S_ECat

    S_CCust --> G_DimCust
    S_ECust --> G_DimCust
    S_ELoc  --> G_DimCust

    S_CPrd  --> G_DimPrd
    S_ECat  --> G_DimPrd

    S_CSls  --> G_FactSales

    %% Styling Color Schemes
    style Files fill:#f9f9f9,stroke:#333,stroke-width:1px
    style Bronze fill:#efebe9,stroke:#5d4037,stroke-width:2px
    style Silver fill:#eceff1,stroke:#455a64,stroke-width:2px
    style Gold fill:#fff9c4,stroke:#fbc02d,stroke-width:2px

```

---

## 🛠️ Viewing Renderings inside GitHub

This technical blueprint leverages **Mermaid** declarative diagramming syntax. GitHub parses, renders, and creates active zoomable interactive vector graphics for these blocks automatically.

* **Local Offline Support:** To render these blueprints inside your local development workspace, install the extensions: `Markdown Preview Mermaid Support` inside your VS Code tool environments.

---

*Last Updated: July 2026*

```

```        int sls_price
    }

    bronze_erp_CUST_AZ12 {
        nvarchar CID
        date BDATE
        nvarchar GEN
    }

    bronze_erp_LOC_A101 {
        nvarchar CID
        nvarchar CNTRY
    }

    bronze_erp_PX_CAT_G1V2 {
        nvarchar ID
        nvarchar CAT
        nvarchar SUBCAT
        nvarchar MAINTENANCE
    }
```

> **Note:** No foreign keys exist in the Bronze layer. Data quality issues such as duplicates, missing values, invalid formats, and inconsistent codes are resolved during the **Bronze → Silver** transformation process.

---

# Full Data Lineage

```text
┌─────────────────────────────────────────────────────────────┐
│                        CSV SOURCES                          │
├───────────────────────┬─────────────────────────────────────┤
│      source_crm/      │            source_erp/              │
│  cust_info.csv        │  CUST_AZ12.csv                      │
│  prd_info.csv         │  LOC_A101.csv                       │
│  sales_details.csv    │  PX_CAT_G1V2.csv                    │
└──────────┬────────────┴────────────┬─────────────────────────┘
           │                         │
           ▼                         ▼
┌──────────────────────┐   ┌──────────────────────┐
│     BRONZE LAYER     │   │     BRONZE LAYER     │
│    (Raw CRM Data)    │   │    (Raw ERP Data)    │
│                      │   │                      │
│ crm_cust_info        │   │ erp_CUST_AZ12        │
│ crm_prd_info         │   │ erp_LOC_A101         │
│ crm_sales_details    │   │ erp_PX_CAT_G1V2      │
└──────────┬───────────┘   └──────────┬───────────┘
           │                          │
           └──────────────┬───────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │      SILVER LAYER      │
              │   (Cleansed Tables)    │
              │                        │
              │ crm_cust_info          │
              │ crm_prd_info           │
              │ crm_sales_details      │
              │ erp_CUST_AZ12          │
              │ erp_LOC_A101           │
              │ erp_PX_CAT_G1V2        │
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │       GOLD LAYER       │
              │     (Star Schema)      │
              │                        │
              │ dim_customers          │
              │ dim_products           │
              │ fact_sales             │
              └────────────────────────┘
```
