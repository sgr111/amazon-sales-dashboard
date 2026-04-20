# 🛒 Amazon India Fashion Sales — End-to-End Analytics Project

## 🔍 Project Overview

This is a complete **end-to-end data analytics project** built on Amazon India fashion sales data. The project covers the full analytics pipeline — from raw data storage and SQL analysis to Excel-based data preparation and an interactive Power BI dashboard.

**Pipeline:**
```
PostgreSQL (Data Storage + SQL Analysis)
        ↓
Excel / Power Query (Data Cleaning + Preparation)
        ↓
Power BI (Interactive Dashboard + DAX Measures)
```

---

## 📊 Dashboard Preview

![Amazon Sales Dashboard](amazon_dasboard.png)

---

## 🗄️ Database Structure

### Table: `amazon_sales`

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | VARCHAR | Unique order identifier |
| `date` | VARCHAR | Order date (MM-DD-YY) |
| `status` | VARCHAR | Shipped, Delivered, Cancelled, Returned, Pending |
| `category` | VARCHAR | Fashion category (Kurta, Set, Saree, etc.) |
| `qty` | INTEGER | Quantity ordered |
| `amount` | NUMERIC(10,2) | Order value in INR |
| `ship_city` | VARCHAR | Delivery city |
| `ship_state` | VARCHAR | Delivery state |
| `fulfilment` | VARCHAR | Amazon or Merchant |
| `b2b` | VARCHAR | Business or consumer order |

---

## 🔧 Stage 1 — PostgreSQL: Data Loading & SQL Analysis

### Data Loading Approach — Staging Table Technique
Loaded raw CSV data with all columns as `VARCHAR` first to avoid import errors, then permanently converted column types:

```sql
ALTER TABLE amazon_sales
ALTER COLUMN amount TYPE NUMERIC(10,2) USING amount::numeric,
ALTER COLUMN qty TYPE INTEGER USING qty::integer;
```

> 💡 This is the professional **staging table approach** used in real data engineering pipelines — load first, validate and cast later.

---

### Query 1 — Total Revenue

```sql
SELECT ROUND(SUM(amount), 2) AS total_revenue
FROM amazon_sales
WHERE status != 'Cancelled';
```

**Result:**

| total_revenue |
|---------------|
| 11774294.87   |

> 💡 **Insight:** Total revenue of ₹1.17 Cr generated from 10,000 orders after excluding cancellations.

---

### Query 2 — Revenue by Category

```sql
SELECT category,
       COUNT(*) AS total_orders,
       SUM(qty) AS units_sold,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY category
ORDER BY revenue DESC;
```

**Result:**

![Revenue by Category](Result_Images/result2.png)

> 💡 **Insight:** Set and Kurta are the top revenue-generating categories. Set drives the highest revenue at ₹27.7L despite lower order volume than Kurta.

---

### Query 3 — Revenue by State (Top 10)

```sql
SELECT ship_state,
       COUNT(*) AS total_orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY ship_state
ORDER BY revenue DESC
LIMIT 10;
```

**Result:**

![Revenue by State](Result_Images/result3.png)

> 💡 **Insight:** Uttar Pradesh, Gujarat, and Maharashtra are the top 3 states — together contributing over 52% of total revenue.

---

### Query 4 — Order Status Breakdown & Cancellation Rate

```sql
SELECT status,
       COUNT(*) AS total_orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM amazon_sales
GROUP BY status
ORDER BY total_orders DESC;
```

**Result:**

| status | total_orders | percentage |
|--------|-------------|------------|
| Shipped | 3024 | 30.24% |
| Delivered | 2974 | 29.74% |
| Cancelled | 2007 | 20.07% |
| Returned | 1013 | 10.13% |
| Pending | 982 | 9.82% |

> 💡 **Insight:** 20.07% cancellation rate identified — addressing this through better product descriptions and delivery estimates could recover significant lost revenue.

---

### Query 5 — Monthly Revenue Trend

```sql
SELECT TO_CHAR(TO_DATE(date, 'MM-DD-YY'), 'YYYY-MM') AS month,
       COUNT(*) AS orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY month
ORDER BY month;
```

**Result:**

![Monthly Revenue](Result_Images/result5.png)

> 💡 **Insight:** October and March show peak revenue months. February 2023 shows a dip — suggesting potential for targeted promotions during slow months to boost revenue by 10–15%.

---

### Query 6 — Top 5 Cities by Orders

```sql
SELECT ship_city,
       ship_state,
       COUNT(*) AS total_orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY ship_city, ship_state
ORDER BY total_orders DESC
LIMIT 5;
```

**Result:**

![Top Cities](Result_Images/result6.png)

---

### Query 7 — B2B vs B2C Revenue Split

```sql
SELECT b2b,
       COUNT(*) AS orders,
       ROUND(SUM(amount), 2) AS revenue
FROM amazon_sales
GROUP BY b2b
ORDER BY orders DESC;
```

**Result:**

![B2B vs B2C](Result_Images/result7.png)

> 💡 **Insight:** B2B orders carry significantly higher average order values — a dedicated B2B strategy could improve overall margins.

---

### Query 8 — Return Rate by Category

```sql
SELECT category,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returns,
       ROUND(SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS return_rate_pct
FROM amazon_sales
GROUP BY category
ORDER BY return_rate_pct DESC;
```

**Result:**

![Return Rate](Result_Images/result8.png)

> 💡 **Insight:** Bottom (12.08%) and Western Dress (10.71%) have the highest return rates — improving size guides for these categories could reduce returns by 8–12%.

---

### Query 9 — Average Order Value by Fulfilment Type

```sql
SELECT fulfilment,
       COUNT(*) AS orders,
       ROUND(AVG(amount), 2) AS avg_order_value
FROM amazon_sales
WHERE status != 'Cancelled'
GROUP BY fulfilment
ORDER BY avg_order_value DESC;
```

**Result:**

![Fulfilment AOV](Result_Images/result9.png)

---

### Query 10 — Cumulative Revenue Over Time

```sql
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
```

**Result:**

![Cumulative Revenue](Result_Images/result10.png)

> 💡 **Insight:** Consistent cumulative growth throughout the year with no major plateaus — confirming healthy business expansion.

---

### Query 11 — Top 3 Categories by Revenue per State (Advanced Window Function)

```sql
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
```

**Result:**

![Top Categories per State](Result_Images/result11.png)

> 💡 **Insight:** Category preferences vary by state — enabling region-specific inventory planning that could improve sell-through rate by ~15%.

---

## 📋 Stage 2 — Excel: Data Cleaning & Preparation

### Steps Performed:

**Data Loading:**
- Loaded all 6 SQL export CSV files into Excel using **Data → Get Data → From Text/CSV**
- Each query result loaded as a separate connected table on individual sheets

**Data Transformations:**
- Converted month column from `YYYY-MM` text format to readable `Apr 2022` format
- Added **MoM Growth %** column using formula `=(C_n - C_{n-1})/C_{n-1}` — dynamic, not hardcoded
- Added **% of Total Revenue** column using `=D_n/SUM($D$3:$D$10)*100`
- Added **Risk Level** column for return rate: 🔴 High (≥11%), 🟡 Medium (10–11%), 🟢 Low (<10%)

**Summary Dashboard Sheet:**
- Created KPI summary with Total Revenue, Total Orders, Cancellation Rate, Avg Order Value
- Built 5 charts: Bar (Category), Bar (State), Line (Monthly), Pie (Status), Bar (Return Rate)

---

## 📊 Stage 3 — Power BI: Interactive Dashboard

### DAX Measures Created:

```dax
CancellationRate = 
CALCULATE(
    SUM(order_status_breakdown_cancellation_rate[percentage]),
    order_status_breakdown_cancellation_rate[status] = "Cancelled"
)
```

```dax
AvgOrderValue = 
DIVIDE(
    SUM(revenue_by_category[revenue]),
    SUM(Monthly_Revenue_Trend[orders])
)
```

### Visuals Built:

| Visual | Data Source | Insight |
|--------|-------------|---------|
| 4 KPI Cards | Multiple tables | Revenue, Orders, Cancellation, AOV |
| Horizontal Bar Chart | revenue_by_category | Set drives highest revenue |
| Line Chart (Smooth) | Monthly_Revenue_Trend | Oct & Mar are peak months |
| Donut Chart | order_status_breakdown | 20.07% cancellation rate |
| Map Visual | revenue_by_state | UP, Gujarat, Maharashtra dominate |
| Bar Chart | return_rate_by_category | Bottom has highest return rate |
| Table | revenue_by_state | Top 10 states ranked |
| 2 Slicers | category, ship_state | Interactive filtering |

---

## 💡 Key Business Insights

- 💰 **Total Revenue:** ₹1,17,74,295 across 10,000 orders
- 🏆 **Top Category:** Set (₹27.7L revenue)
- 📍 **Top State:** Uttar Pradesh (₹24.7L — 21% of total)
- ❌ **Cancellation Rate:** 20.07% — biggest revenue recovery opportunity
- 📈 **Peak Months:** October 2022 and March 2023
- 🔄 **Highest Return Rate:** Bottom category at 12.08%
- 🎯 **Targeted promotions** during Feb dip could improve order volume by 10–15%
- 📦 **Regional inventory planning** based on state-category preferences could improve sell-through by ~15%

---

## 🛠️ Tools Used

| Stage | Tool | Purpose |
|-------|------|---------|
| Stage 1 | PostgreSQL 18 + pgAdmin 4 | Data storage, SQL analysis |
| Stage 2 | Microsoft Excel + Power Query | Data cleaning, preparation, charts |
| Stage 3 | Microsoft Power BI Desktop | Interactive dashboard, DAX measures |
| Version Control | Git + GitHub | Project hosting |
| Data Generation | Python | Clean synthetic dataset creation |

---

## 📁 File Structure

```
amazon-sales-analysis/
│
├── README.md                          ← You are here
├── amazon_sales_clean.csv             ← Clean dataset (10,000 rows)
├── analysis_queries.sql               ← All 11 PostgreSQL queries
├── Amazon_Sales_Dashboard.xlsx        ← Excel dashboard + charts
├── Amazon_Sales_Dashboard.pbix        ← Power BI interactive dashboard
├── amazon_dasboard.png                ← Dashboard screenshot
└── Result_Images/
    └── result2.png ... result11.png   ← Query output screenshots
```

---

## ▶️ How to Run

**PostgreSQL:**
1. Install PostgreSQL and pgAdmin 4
2. Create database: `ecommerce_project`
3. Run `CREATE TABLE` query from `analysis_queries.sql`
4. Import `amazon_sales_clean.csv` via pgAdmin Import/Export
5. Run all queries from `analysis_queries.sql`

**Excel:**
1. Open `Amazon_Sales_Dashboard.xlsx`
2. Go to Data → Refresh All to reconnect queries

**Power BI:**
1. Open `Amazon_Sales_Dashboard.pbix` in Power BI Desktop
2. Update data source path to your local Excel file if needed
3. Click Refresh to load latest data

---

## 👤 Author

**Sourabh Sagar**
[GitHub Profile](https://github.com/01sourabhsagar)

---

*Thank you!*
