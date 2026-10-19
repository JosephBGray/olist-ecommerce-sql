-- Olist Dataset Project
-- Business Questions

-- 1. Who are the top 10 sellers by revenue, and how concentrated is revenue among them?
-- Working with order_items, sellers

SELECT
    s.seller_id,
    s.seller_state,
    s.seller_city,
    s.seller_zip_code_prefix, -- location columns included for potential follow-up analysis
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_transaction_value, -- additional column including shipping revenue
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM olist_order_items_dataset oi
JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state, s.seller_zip_code_prefix
ORDER BY product_revenue DESC
LIMIT 10;

-- A few first-glance observations:
-- There is no heavy outlier dominating the revenue. There is a somewhat steady slope from 1-10.
-- Number of orders does not seem to correlate strongly with revenue. The 2nd highest revenue has only about 1/3 of the total orders of the highest, while the 3rd has the most orders of all.
-- Sorting by total_transaction_value changes the order quite a bit showing us that shipping revenue has greater impact with some sellers.
-- 9 of the top 10 sellers are in São Paulo.

-- --------------------

-- 2. Which states have the highest customer count vs. highest revenue per customer?
-- Working with customers, orders, order_items

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_transaction_value, -- same column with shipping revenue used in question 1.
    ROUND(SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id), 2) AS revenue_per_customer,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT c.customer_unique_id), 2) AS total_per_customer -- total with shipping per customer
FROM olist_customers_dataset c
JOIN delivered_orders o ON c.customer_id = o.customer_id -- Optional to swap delivered_orders with olist_orders_dataset to include ALL orders, not just delivered ones
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue_per_customer DESC;

-- Try ordering by total_customers, total_per_customer, or total_revenue as well.
-- At a glance, customer count and revenue_per_customer do not correlate strongly
-- If anything, the states with higher population density tend to have lower revenue_per_customer
-- The state with the most customers has the lowest revenue_per_customer, while the top 10 revenue_per_customer states have relatively low total_customers.

-- --------------------

-- 3. What's the average delivery time (purchase → delivered), and does it vary meaningfully by state or by seller?
-- Working with delivered_orders, olist_customers_dataset, olist_sellers_dataset

-- This shows the average delivery time across the whole dataset to be 12 days.
SELECT ROUND(AVG(DATEDIFF(order_delivered_date, order_purchase_date)), 0) AS avg_delivery_days
FROM delivered_orders;

-- This shows the average delivery time and total orders by state.
SELECT
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_date, o.order_purchase_date)), 1) AS avg_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM delivered_orders o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- Slowest state averages 29.3 days; fastest averages 8.7.

-- This shows average delivery time and total orders by seller.
SELECT
    oi.seller_id,
    ROUND(AVG(DATEDIFF(o.order_delivered_date, o.order_purchase_date)), 1) AS avg_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM delivered_orders o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 10 -- removes extreme outlier noise for sellers with under 10 orders
ORDER BY avg_delivery_days DESC;

-- Slowest seller averages 37.5 days; fastest averages 3.9.

-- This breaks out the average delivery time by seller into customer states. (i.e., how long does it take Seller X to deliver to São Paulo?)
SELECT
    oi.seller_id,
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_date, o.order_purchase_date)), 1) AS avg_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM delivered_orders o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY oi.seller_id, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 10
ORDER BY avg_delivery_days DESC;

-- Slowest seller-to-state pairing averages 37.1 days; fastest averages 2.9.

-- ----------------

-- 4. Is there a relationship between delivery delay and review score?
-- Working with reviews, delivered_orders

-- This shows the difference between estimated delivery date and actual delivery date.
SELECT
    r.review_score,
    ROUND(AVG(DATEDIFF(o.order_delivered_date, o.order_estimated_delivery_date)), 1) AS avg_delay_days,
    COUNT(*) AS total_reviews
FROM delivered_orders o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;

-- A quick glance shows the vast majority of orders received a 5 star review, with 2nd most being 4 star.
-- Interestingly, the average delivery time is faster than estimated regardless of the review score. Possibly Olist always overestimates so that the delivery always seems fast.
-- However, the earlier an order arrives relative to its estimate, the higher the review score.
-- Managing and beating expectations may be more valuable than raw delivery speed.
-- Though there is a clear correlation here, it's not necessarily a direct cause - other factors feed into review score (faulty product, not as advertised, etc.).

-- ----------------

-- 5. What payment types are most common, and do orders paid via installments have different average order values than one-time payments?
-- Working with order_payments

-- This breaks out payments by payment type and shows percentage.
SELECT
    payment_type,
    COUNT(*) AS total_payments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_payments DESC;

-- This shows orders paid in installments vs. one-time payments.
SELECT
    CASE
        WHEN payment_installments = 1 THEN 'One-time'
        ELSE 'Installments'
    END AS payment_group,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(payment_value), 2) AS avg_order_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY payment_group;

-- As expected, installment orders average roughly double the order value of one-time payments.

-- This shows average number of installments for all credit card orders paid in installments.
SELECT
    ROUND(AVG(payment_installments), 1) AS avg_installments,
    ROUND(AVG(payment_value), 2) AS avg_order_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card' AND payment_installments > 1;
