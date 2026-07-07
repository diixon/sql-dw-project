# Data Catalog — Gold Layer

Business-facing documentation for the views in the `gold` schema. These are
the objects analysts and reporting tools should query directly.

---

## gold.dim_customers

Customer dimension. One row per customer, combining CRM master data with
supplementary attributes from the ERP system.

| Column             | Type          | Description                                                                 |
|--------------------|---------------|-------------------------------------------------------------------------------|
| customer_key       | INT           | Surrogate key uniquely identifying each customer row in this dimension.       |
| customer_id        | INT           | Source system customer ID, from the CRM system (`cst_id`).                    |
| customer_number    | NVARCHAR(50)  | Customer business key used to join to other source systems (`cst_key`).       |
| first_name         | NVARCHAR(50)  | Customer's first name.                                                        |
| last_name          | NVARCHAR(50)  | Customer's last name.                                                         |
| country            | NVARCHAR(50)  | Customer's country, standardized (e.g. 'Germany', 'United States', 'Unknown').|
| marital_status     | NVARCHAR(50)  | Standardized marital status: 'Married', 'Single', or 'Unknown'.                |
| gender             | NVARCHAR(50)  | Standardized gender: 'Male', 'Female', or 'Unknown'. Sourced from CRM first, falling back to the ERP system when CRM has no value. |
| birthdate          | DATE          | Customer's date of birth, sourced from the ERP system.                        |
| create_date        | DATE          | Date the customer record was created in the CRM system.                       |

---

## gold.dim_products

Product dimension. One row per **current** product (historical, discontinued
versions of a product are excluded from this view).

| Column          | Type          | Description                                                                    |
|-----------------|---------------|---------------------------------------------------------------------------------|
| product_key     | INT           | Surrogate key uniquely identifying each product row in this dimension.          |
| product_id      | INT           | Source system product ID, from the CRM system (`prd_id`).                       |
| product_number  | NVARCHAR(50)  | Product business key used to join to sales transactions (`prd_key`).            |
| product_name    | NVARCHAR(50)  | Product name.                                                                    |
| category_id     | NVARCHAR(50)  | Category identifier, derived from the product key, used to join to ERP category data. |
| category        | NVARCHAR(50)  | Product category, from the ERP system.                                          |
| subcategory     | NVARCHAR(50)  | Product subcategory, from the ERP system.                                       |
| maintenance     | NVARCHAR(50)  | Maintenance flag/type, from the ERP system.                                     |
| cost            | INT           | Product cost. Defaults to 0 if not provided by the source system.               |
| product_line    | NVARCHAR(50)  | Standardized product line: 'Road', 'Mountain', 'Sport', 'Touring', or 'Unknown'. |
| start_date      | DATE          | Date this version of the product became active.                                 |

---

## gold.fact_sales

Sales fact table. One row per sales order line, linked to the customer and
product dimensions via their surrogate keys.

| Column         | Type          | Description                                                          |
|----------------|---------------|--------------------------------------------------------------------------|
| order_number   | NVARCHAR(50)  | Sales order number.                                                        |
| product_key    | INT           | Foreign key to `gold.dim_products.product_key`.                           |
| customer_key   | INT           | Foreign key to `gold.dim_customers.customer_key`.                         |
| order_date     | DATE          | Date the order was placed.                                                |
| shipping_date  | DATE          | Date the order was shipped.                                               |
| due_date       | DATE          | Date payment for the order was due.                                       |
| sales_amount   | INT           | Total sales amount for the line. Recalculated from quantity × price if the source value was missing, non-positive, or inconsistent. |
| quantity       | INT           | Quantity sold.                                                            |
| price          | INT           | Unit price. Derived from sales ÷ quantity if the source value was missing or less than 1. |
