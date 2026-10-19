# Olist E-Commerce SQL Analysis

A SQL portfolio project analyzing the Olist Brazilian E-Commerce dataset: a real, multi-table dataset covering ~100K orders across customers, sellers, products, payments, reviews, and delivery logistics.

**Tools:** MySQL &nbsp;|&nbsp; **Dataset:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) &nbsp;|&nbsp; **Dashboard:** [Interactive version on Tableau Public](https://public.tableau.com/app/profile/joseph.gray6923/viz/Olist_Dashboard_17912242784130/OlistE-Commerce)

---

## Dataset

The dataset is split across 9 relational tables (customers, orders, order_items, products, sellers, order_payments, order_reviews, geolocation, and a product category translation table), joined primarily through `order_id`, `customer_id`, `product_id`, and `seller_id`.

The raw CSVs are not included in this repo. Download them from the Kaggle link above.

## Files in This Repo

| File | Contents |
|---|---|
| `Olist_Data_Cleaning.sql` | Duplicate checks, NULL/empty-string audits, a fix for missing product categories, a UTF-8 BOM fix, date/type conversion, and a reusable `delivered_orders` view |
| `Olist_Business_Questions.sql` | Five business questions answered with multi-table joins, aggregation, a window function, and CASE-based grouping, each with commented findings |

## Data Cleaning Summary

- **Duplicates:** Checked the 7 tables with primary or composite keys. Only `order_reviews` showed apparent duplicates, and these turned out to be single reviews legitimately linked to multiple orders, not true dupes.
- **NULLs and empty strings:** Audited every table's key join and filter columns.
- **Missing categories:** 610 products (~1.8%) had no category name. Labeled them `'unknown'` rather than dropping them, to avoid understating order and revenue totals tied to those products.
- **Encoding:** Fixed a UTF-8 BOM that had attached itself to the first column name in the category translation table.
- **Dates:** Converted order date/timestamp columns from text to `DATETIME`, handling empty strings as NULL along the way, and added day-level date columns for delivery-time calculations.
- **Reusable view:** Built a `delivered_orders` view used throughout the business questions, since several needed completed transactions rather than all order statuses.
- **Geolocation:** This table has no natural primary key and contains many duplicate lat/long rows per zip code prefix. It isn't used in the business questions, so it was left as-is.

## Business Questions & Key Findings

### 1. Who are the top 10 sellers by revenue, and how concentrated is revenue among them?

- Revenue slopes down gradually across the top 10 rather than being dominated by one outlier.
- Order count doesn't track revenue closely. The #3 seller by revenue has the most orders of the group, while the #2 seller has roughly a third of the top seller's order volume.
- Sorting by total transaction value (including shipping) reshuffles the ranking noticeably, so shipping revenue matters more for some sellers than others.
- 9 of the top 10 sellers are based in São Paulo.

### 2. Which states have the highest customer count vs. the highest revenue per customer?

- The two don't move together. If anything, the relationship is inverse.
- The state with the most customers has the lowest revenue per customer, while the states with the highest revenue per customer tend to have relatively small customer bases.

### 3. What's the average delivery time, and does it vary by state or seller?

- Average delivery time across the dataset is **12 days**.
- **By customer state:** ranges from 8.7 to 29.3 days.
- **By seller** (sellers with 10+ orders, to reduce noise): ranges from 3.9 to 37.5 days.
- **By seller and destination state:** a similar spread (2.9 to 37.1 days), so delivery time depends on both who ships the order and where it's going.

### 4. Is there a relationship between delivery delay and review score?

- The vast majority of reviews are 5-star, with 4-star second.
- On average, orders arrived *earlier* than the estimated delivery date in every review-score group. Olist may deliberately pad its delivery estimates so that deliveries feel fast.
- The earlier an order arrived relative to its estimate, the higher its review score tended to be. Beating customer expectations may matter more for satisfaction than raw delivery speed.
- This is a correlation, not a proven cause. Other factors (product quality, whether the item matched its listing, etc.) also drive review scores.

### 5. What payment types are most common, and do installment orders differ in value from one-time payments?

- Credit card is by far the most common payment type (~74% of payments), followed by boleto (~19%), voucher (~6%), and debit card (~2%).
- Credit card orders paid in installments average roughly **double** the value of one-time credit card payments, consistent with shoppers using installments to afford larger purchases.

## Skills Demonstrated

Multi-table joins · aggregation (`GROUP BY`, `HAVING`) · window functions · `CASE` logic · date functions (`DATEDIFF`) · views · data cleaning (duplicate/NULL audits, type conversion, encoding fixes) · business-question-driven analysis

## How to Run

1. Download the CSVs from Kaggle and load each into a MySQL schema, keeping the original file names as table names.
2. Run `Olist_Data_Cleaning.sql` top to bottom.
3. Run the queries in `Olist_Business_Questions.sql`.
