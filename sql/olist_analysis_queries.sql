/* ============================================================
   Brazilian E-Commerce (Olist) — SQL Analysis
   Engine: MySQL 8   |   Schema: Brazillian
   ------------------------------------------------------------
   Tables are loaded into MySQL at the end of
   notebooks/olist_eda_and_cleaning.ipynb (section 12).

   Core tables used:
     order_details   one row per order (status, timestamps)
     order_items     one row per item in an order (price, shipping_cost)
     order_reviews   one review per order (review_score)
     customers       customer_id → customer_unique_id, city, state, zipcode
     sellers         seller city / state
     product_details product attributes and category (Portuguese)
     product_category_name_translation  Portuguese → English category

   Conventions:
     - Revenue = SUM(order_items.price) (excludes shipping_cost)
     - Days vs. estimate: negative = early, positive = late
     - Time-series analysis is scoped to Jan 2017 – Aug 2018
       (2016 pilot months and partial Sep 2018 excluded)
   ============================================================ */


/* --------------------------------------------------------------
   Q1: How does review score relate to delivery timing?
   -------------------------------------------------------------- */
SELECT 
    CASE WHEN r.review_score <= 2 THEN 'Low (1-2)' ELSE 'High (3-5)' END AS review_group,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 1) AS avg_days_vs_estimate,
    COUNT(*) AS order_count
FROM order_reviews r
JOIN order_details o ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY review_group;

/* 
   avg_days_vs_estimate is negative for both groups, meaning both arrive 
   before the estimated date on average — negative = early, positive = late.

   High reviews:  -12.9 days on average (delivered ~13 days early)   | 83,404 orders
   Low reviews:   -5.1 days on average  (delivered ~5 days early)    | 12,203 orders

   Low-review orders are, on average, delivered much closer to (or past) 
   the estimated date than high-review orders — the cushion of early 
   delivery shrinks sharply as review score drops. This lines up with 
   the Python finding that 27.58% of low-rated orders were delivered late.
*/


/* --------------------------------------------------------------
   Q2: Which city generates the most revenue?
   -------------------------------------------------------------- */
SELECT 
    c.customer_city,
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM order_details o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

/* 
   Sao Paulo generates by far the most revenue: $1,914,924.54 across 15,402 orders.
   Second is Rio de Janeiro with $992,538.86 across 6,834 orders — less than 
   half of Sao Paulo's revenue.
*/


/* --------------------------------------------------------------
   Q3: Revenue and demand by product category
   -------------------------------------------------------------- */
SELECT 
    t.product_category_name_english AS category,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN product_details p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

/* 
   Highest-selling category by volume: bed_bath_table — 11,115 units sold, 
   $1,036,988.68 revenue, avg unit price $93.30.

   Highest revenue category: health_beauty — 9,670 units sold, $1,258,681.34 
   revenue, avg unit price $130.16.

   Highest avg unit price: watches_gifts — 5,991 units sold, $1,205,005.68 
   revenue, avg unit price $201.14.

   Takeaway: bed_bath_table sells the most units but at the lowest price point 
   and lowest revenue of the three. health_beauty earns the most revenue with 
   a mid-range price and fewer units sold than bed_bath_table. watches_gifts 
   has the highest price point and sells the fewest units of the three, but 
   still lands second in total revenue — high price per unit compensates for 
   lower volume.
*/



/* --------------------------------------------------------------
   Q4a: Which sellers handle the most orders, and how do they score?
   -------------------------------------------------------------- */
SELECT
    oi.seller_id,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT o.order_id) AS orders_handled
FROM order_items oi
JOIN order_details o ON oi.order_id = o.order_id
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY oi.seller_id
HAVING orders_handled >= 20
ORDER BY orders_handled DESC
LIMIT 10;

/* --------------------------------------------------------------
   Q4b: Which sellers have the best review scores? (min. 20 orders)
   -------------------------------------------------------------- */
SELECT
    oi.seller_id,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT o.order_id) AS orders_handled
FROM order_items oi
JOIN order_details o ON oi.order_id = o.order_id
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY oi.seller_id
HAVING orders_handled >= 20
ORDER BY avg_review_score DESC, orders_handled DESC
LIMIT 10;

/* 
   Q4a) Highest-volume seller: 6560211a19b47992c3666cc44a7e94c0 (1,834 orders) 
   with an average review score 3.91.
   
   Q4b) Highest-rated seller (with at least 20 orders): 48efc9d94a9834137efd9ea76b065a38 
   — perfect 5.0 average review score across 33 orders.

   Note: Q4a and Q4b are two different sorts of the same underlying data — 
   volume leaders and satisfaction leaders are not the same sellers, which is 
   itself worth calling out: high volume doesn't guarantee high satisfaction, 
   and vice versa.
*/


/* --------------------------------------------------------------
   Q5: How does shipping cost and delivery time vary by state?
   -------------------------------------------------------------- */
SELECT 
    c.customer_state,
    ROUND(AVG(oi.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_approved_at)), 1) AS avg_delivery_days
FROM order_details o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_shipping_cost ASC;

/* 
   Highest avg shipping cost: Roraima (RR) and Paraíba (PB), both at $43.09 — 
   with avg delivery times of 27.7 and 19.9 days respectively.

   Lowest avg shipping cost: Sao Paulo (SP) at $15.11, with an avg delivery 
   time of 8.2 days — the fastest and cheapest state to deliver to, consistent 
   with SP also being the highest-revenue and highest-order-volume state.
*/


/* --------------------------------------------------------------
   Q6: Which products generate the most revenue, and where do they sell from?
   -------------------------------------------------------------- */
SELECT 
    oi.product_id,
    s.seller_city,
    s.seller_state,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    COUNT(oi.order_item_id) AS units_sold
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY oi.product_id, s.seller_city, s.seller_state
ORDER BY product_revenue DESC
LIMIT 10;

/* 
   Highest revenue per product: product bb50f2e236e5eea0100680137654686c
   (seller in Sao Bernardo do Campo, SP) — $63,885.00 across 195 units sold.
   Second: product 6cdd53843498f92890544667809f1595 (Curitiba, PR) —
   $54,730.20 across 156 units.

   Most units among the top 10: product aca2eb7d00ea1a7b8ebd4e68314663af
   (Sao Paulo, SP) — 527 units sold but only $37,608.90 revenue, meaning a
   much lower price point than the top product. 6 of the top 10 revenue
   products are sold from SP-based sellers.
*/


/* --------------------------------------------------------------
   Q7: Which zip codes generate the most revenue?
   -------------------------------------------------------------- */
SELECT 
    c.zipcode,
    c.customer_city,
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM order_details o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.zipcode, c.customer_city, c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

/* 
   Best-performing zip code: 22790 (Rio de Janeiro) — $22,154.89 total revenue 
   across 142 orders.
*/


/* --------------------------------------------------------------
   Q8: How much revenue comes from repeat customers vs. one-time buyers?
   -------------------------------------------------------------- */
SELECT 
    CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS total_revenue,
    ROUND(AVG(total_spent), 2) AS avg_revenue_per_customer
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN order_details o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
) AS customer_summary
GROUP BY customer_type;

/* 
   One-time customers: 92,507 customers, $12,828,351.84 total revenue, 
   $138.67 average revenue per customer.

   Repeat customers: 2,913 customers, $763,291.86 total revenue, 
   $262.03 average revenue per customer — nearly double the average spend 
   of a one-time customer, despite being under 3% of the customer base.
*/


/* --------------------------------------------------------------
   Q9: Which states have the highest order failure (cancel/unavailable) rate?
   -------------------------------------------------------------- */
SELECT 
    c.customer_state,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_status IN ('canceled','unavailable') THEN 1 ELSE 0 END) AS failed_orders,
    ROUND(100.0 * SUM(CASE WHEN o.order_status IN ('canceled','unavailable') THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM order_details o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING total_orders >= 100
ORDER BY failure_rate_pct DESC;

/* 
   Sao Paulo (SP) has the most orders overall (41,746) with a low failure 
   rate of 1.48%.

   Highest failure rate: Rondônia (RO) at 2.77%.
   Lowest failure rate: Alagoas (AL) at 0.48%.

   No clear link between order volume and failure rate — SP handles the most 
   volume with a below-average failure rate, while RO and AL are both 
   lower-volume states at opposite ends of the failure-rate spectrum.
*/

/* --------------------------------------------------------------
  Q10: Which month had the highest order volume, and which month generated the most revenue?
   -------------------------------------------------------------- */
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM order_details o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status != 'canceled'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY month
ORDER BY month;

/*
Excluding 2016 (pilot-phase data, 1–2 orders per month) 
and September 2018 (partial month — data collection ends mid-month), 

November 2017 had the highest order volume (7,421 orders) 
and highest total revenue ($1,003,862.14) of any complete month in the dataset.
*/
