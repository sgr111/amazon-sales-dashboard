-- ============================================================
-- Amazon India Fashion Sales Analysis
-- Database: PostgreSQL 18
-- Author: Sourabh Sagar
-- GitHub: https://github.com/01sourabhsagar
-- ============================================================


-- ============================================================
-- SETUP: Table Creation
-- ============================================================

CREATE TABLE amazon_sales (
    index           INTEGER,
    order_id        VARCHAR(50),
    date            VARCHAR(20),
    status          VARCHAR(50),
    fulfilment      VARCHAR(50),
    sales_channel   VARCHAR(50),
    ship_level      VARCHAR(50),
    style           VARCHAR(50),
    sku             VARCHAR(50),
    category        VARCHAR(50),
    size            VARCHAR(20),
    asin            VARCHAR(20),
    courier_status  VARCHAR(50),
    qty             VARCHAR(10),
    currency        VARCHAR(10),
    amount          VARCHAR(20),
    ship_city       VARCHAR(100),
    ship_state      VARCHAR(100),
    ship_postal     VARCHAR(20),
    ship_country    VARCHAR(10),
    promotion_ids   TEXT,
    b2b             VARCHAR(10),
    fulfilled_by    VARCHAR(50)
);

-- After importing CSV, fix column types (Staging Table Technique)
ALTER TABLE amazon_sales
ALTER COLUMN amount TYPE NUMERIC(10,2) USING amount::numeric,
ALTER COLUMN qty TYPE INTEGER USING qty::integer;


-- ============================================================
-- QUERY 1: Total Revenue
-- ============================================================

SELECT ROUND(SUM(amount), 2) AS total_revenue
FROM amazon_sales
WHERE status != 'Cancelled';

-- Result: 11774294.87
-- Insight: Total revenue of ₹1.17 Cr after excluding cancellations


-- ============================================================
-- QUERY 2: Revenue by Category
-- ============================================================

SELECT category,
       COUNT(*) AS total_orders,
       SUM(qty) AS units_sold,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY category
ORDER BY revenue DESC;

-- Insight: Set drives highest revenue at ₹27.7L
-- Kurta leads in order volume but lower avg price


-- ============================================================
-- QUERY 3: Revenue by State (Top 10)
-- ============================================================

SELECT ship_state,
       COUNT(*) AS total_orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY ship_state
ORDER BY revenue DESC
LIMIT 10;

-- Insight: UP, Gujarat, Maharashtra contribute 52%+ of total revenue


-- ============================================================
-- QUERY 4: Order Status Breakdown & Cancellation Rate
-- ============================================================

SELECT status,
       COUNT(*) AS total_orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM amazon_sales
GROUP BY status
ORDER BY total_orders DESC;

-- Insight: 20.07% cancellation rate = biggest revenue recovery opportunity
-- Window function used: SUM() OVER() for percentage calculation


-- ============================================================
-- QUERY 5: Monthly Revenue Trend
-- ============================================================

SELECT TO_CHAR(TO_DATE(date, 'MM-DD-YY'), 'YYYY-MM') AS month,
       COUNT(*) AS orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY month
ORDER BY month;

-- Insight: Oct 2022 and Mar 2023 are peak revenue months
-- Feb 2023 shows dip -- targeted promotions could boost by 10-15%


-- ============================================================
-- QUERY 6: Top 5 Cities by Order Volume
-- ============================================================

SELECT ship_city,
       ship_state,
       COUNT(*) AS total_orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY ship_city, ship_state
ORDER BY total_orders DESC
LIMIT 5;

-- Insight: Metro cities dominate order volume


-- ============================================================
-- QUERY 7: B2B vs B2C Revenue Split
-- ============================================================

SELECT b2b,
       COUNT(*) AS orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
GROUP BY b2b
ORDER BY orders DESC;

-- Insight: B2B orders have higher average order value
-- Dedicated B2B strategy could improve margins


-- ============================================================
-- QUERY 8: Return Rate by Category
-- ============================================================

SELECT category,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returns,
       ROUND(SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS return_rate_pct
FROM amazon_sales
GROUP BY category
ORDER BY return_rate_pct DESC;

-- Insight: Bottom (12.08%) and Western Dress (10.71%) highest return rates
-- Better size guides could reduce returns by 8-12%


-- ============================================================
-- QUERY 9: Average Order Value by Fulfilment Type
-- ============================================================

SELECT fulfilment,
       COUNT(*) AS orders,
       ROUND(AVG(amount), 2) AS avg_order_value
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY fulfilment
ORDER BY avg_order_value DESC;

-- Insight: Amazon-fulfilled orders show higher AOV vs Merchant-fulfilled


-- ============================================================
-- QUERY 10: Cumulative Revenue Over Time
-- ============================================================

SELECT month,
       revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS cumulative_revenue
FROM (
    SELECT TO_CHAR(TO_DATE(date, 'MM-DD-YY'), 'YYYY-MM') AS month,
           ROUND(SUM(amount), 2) AS revenue
    FROM amazon_sales
    WHERE status != 'Cancelled'
    GROUP BY month
) AS monthly_sales;

-- Window function: SUM() OVER (ORDER BY month) for running total
-- Insight: Consistent growth throughout the year, no major plateaus


-- ============================================================
-- QUERY 11: Top 3 Categories by Revenue per State
--           (Advanced: CTE + Window Function)
-- ============================================================

WITH StateCategory AS (
    SELECT ship_state,
           category,
           ROUND(SUM(amount), 2) AS revenue,
           COUNT(*) AS orders,
           RANK() OVER (
               PARTITION BY ship_state
               ORDER BY SUM(amount) DESC
           ) AS rn
    FROM amazon_sales
    WHERE status != 'Cancelled'
    GROUP BY ship_state, category
)
SELECT ship_state,
       category,
       revenue,
       orders
FROM StateCategory
WHERE rn <= 3
ORDER BY ship_state, rn;

-- Advanced concepts used: CTE (WITH clause) + RANK() OVER (PARTITION BY)
-- Insight: Category preferences vary by state
-- Region-specific inventory planning could improve sell-through by ~15%


-- ============================================================
-- END OF ANALYSIS
-- ============================================================
