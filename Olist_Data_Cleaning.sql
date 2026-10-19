-- Olist Dataset Project
-- Cleaning

-- Checking for duplicate primary keys
-- Running the same query across each table for a quick dupe scan

-- customers
SELECT customer_id, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- orders
SELECT order_id, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- order_items - composite primary key: order_id + order_item_id
SELECT order_id, order_item_id, COUNT(*)
FROM olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- products
SELECT product_id, COUNT(*)
FROM olist_products_dataset
GROUP BY product_id
HAVING COUNT(*) > 1;

-- sellers
SELECT seller_id, COUNT(*)
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- order_payments - composite primary key: order_id + payment_sequential
SELECT order_id, payment_sequential, COUNT(*)
FROM olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- order_reviews
SELECT review_id, COUNT(*)
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1;  -- reviews is the only table with possible duplicates

SELECT review_id, COUNT(DISTINCT order_id) AS order_count
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING order_count > 1; -- the same exact number of 'possible dupes' are not actual dupes - some review_id are just attached to >1 order_id

-- No deduping needed

-- Check for NULLs and empty strings
-- Similar process to dupe check - running same query across each table to scan for NULLs and empty strings
-- This time showing each query - only checking in columns that may be used for joining or filtering and only commenting if any NULLs / empty strings are found

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL OR customer_unique_id = '' THEN 1 ELSE 0 END) AS missing_customer_unique_id
FROM olist_customers_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL OR geolocation_zip_code_prefix = '' THEN 1 ELSE 0 END) AS missing_geolocation_zip_code_prefix
FROM olist_geolocation_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END) AS missing_seller_id
FROM olist_order_items_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS missing_order_id
FROM olist_order_payments_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN review_id IS NULL OR review_id = '' THEN 1 ELSE 0 END) AS missing_review_id
FROM olist_order_reviews_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS missing_customer_id
FROM olist_orders_dataset;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END) AS missing_product_category_name
FROM olist_products_dataset;

-- small number (610) of missing product_category_name - labeling them

UPDATE olist_products_dataset
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL OR product_category_name = '';

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END) AS missing_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL OR seller_zip_code_prefix = '' THEN 1 ELSE 0 END) AS missing_seller_zip_code_prefix
FROM olist_sellers_dataset;

-- Fixed BOM attached to column name
ALTER TABLE product_category_name_translation
RENAME COLUMN ï»¿product_category_name TO product_category_name_pt;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_category_name_pt IS NULL OR product_category_name_pt = '' THEN 1 ELSE 0 END) AS missing_product_category_name_pt,
    SUM(CASE WHEN product_category_name_english IS NULL OR product_category_name_english = '' THEN 1 ELSE 0 END) AS missing_product_category_name_english
FROM product_category_name_translation;

-- Dupes and NULLs have been taken care of. Moving on to further cleaning and standardization.

-- View of delivered orders only. Useful for questions tied to revenue.
CREATE VIEW delivered_orders AS
SELECT * FROM olist_orders_dataset
WHERE order_status = 'delivered';

-- For delivery time, I want to use a day-level granularity, so here I am making two new columns for purchase and delivery dates.

ALTER TABLE olist_orders_dataset
ADD COLUMN order_purchase_date DATE,
ADD COLUMN order_delivered_date DATE;

-- Changing empty strings to NULL before converting columns to DATETIME.
UPDATE olist_orders_dataset
SET order_purchase_timestamp = NULLIF(order_purchase_timestamp, ''),
    order_delivered_customer_date = NULLIF(order_delivered_customer_date, '');

-- Changing empty strings to NULL for remaining columns in case I choose to use them.
UPDATE olist_orders_dataset
SET order_approved_at = NULLIF(order_approved_at, ''),
    order_delivered_carrier_date = NULLIF(order_delivered_carrier_date, ''),
    order_estimated_delivery_date = NULLIF(order_estimated_delivery_date, '');

-- Reformatting from text to datetime
ALTER TABLE olist_orders_dataset
MODIFY COLUMN order_purchase_timestamp DATETIME,
MODIFY COLUMN order_delivered_customer_date DATETIME;

-- Reformatting remaining columns.
ALTER TABLE olist_orders_dataset
MODIFY COLUMN order_approved_at DATETIME,
MODIFY COLUMN order_delivered_carrier_date DATETIME,
MODIFY COLUMN order_estimated_delivery_date DATETIME;

-- Updating new columns with date.
UPDATE olist_orders_dataset
SET order_purchase_date = DATE(order_purchase_timestamp),
    order_delivered_date = DATE(order_delivered_customer_date);

-- Dropping and recreating the view so it picks up the new columns (MySQL expands SELECT * when a view is created).
DROP VIEW delivered_orders;

CREATE VIEW delivered_orders AS
SELECT * FROM olist_orders_dataset
WHERE order_status = 'delivered';


-- Joining product category name with English translation
SELECT product_id, products.product_category_name, translation.product_category_name_pt, translation.product_category_name_english
FROM olist_products_dataset as products
INNER JOIN product_category_name_translation as translation
    ON products.product_category_name = translation.product_category_name_pt;

-- Geolocation has no primary key and contains duplicates
-- Geolocation table is not used in this project's business questions, so left unaggregated/uncleaned here.
