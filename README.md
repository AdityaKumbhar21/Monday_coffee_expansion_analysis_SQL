# ☕ Monday Coffee Expansion Analysis

## Overview

**Monday Coffee**, an online coffee retailer, is planning to expand its operations by opening physical coffee shops in three of India's top cities. Since its launch in **January 2023**, the company has seen strong online sales and positive customer feedback across multiple cities. As a Data Analyst, your role is to analyze the sales data and recommend the top three cities for expansion based on data-driven insights.

This project uses SQL (MySQL/PostgreSQL) to perform exploratory data analysis (EDA) on the available datasets and generate business recommendations.

---

## Objective

The goal of this analysis is to identify **the top three cities** where Monday Coffee should open new stores. The recommendations are based on factors such as:

- Total sales and customer behavior
- City population and estimated coffee consumers
- Average sales per customer
- Estimated rent and cost-efficiency
- Market potential and growth trends

---

## Dataset Details

The analysis uses the following tables:

- `city` – City-level data including population, estimated rent, and ranking
- `customers` – Customer demographic and location information
- `sales` – Transaction-level data of purchases
- `products` – Coffee products with product IDs and names

---

## 📌 Questions & Queries Used

### 1. Coffee Consumers Count  
```sql
SELECT 
  city_name,
  ROUND(population * 0.25) AS coffee_consumers,
  city_rank
FROM city
ORDER BY coffee_consumers DESC;
```

### 2. Total Revenue from Coffee Sales  
```sql
SELECT
  YEAR(sale_date) AS year,
  QUARTER(sale_date) AS quarter,
  SUM(total) AS total_sales
FROM sales
WHERE QUARTER(sale_date) = 4 AND YEAR(sale_date) = 2023
GROUP BY YEAR(sale_date), QUARTER(sale_date);
```

### 3. Total Sales by City (Top 5)  
```sql
SELECT
  c.city_name AS city,
  SUM(s.total) AS total_sales
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
WHERE QUARTER(sale_date) = 4 AND YEAR(sale_date) = 2023
GROUP BY c.city_name
ORDER BY total_sales DESC
LIMIT 5;
```

### 4. Sales Count for Each Product  
```sql
SELECT 
  p.product_name,
  COUNT(s.product_id) AS units_sold
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY units_sold DESC;
```

### 5. Average Sales Amount per City  
```sql
SELECT
  c.city_name AS city,
  COUNT(DISTINCT s.customer_id) AS customer_count,
  ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sales_per_cust
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
GROUP BY c.city_name
ORDER BY avg_sales_per_cust DESC;
```

### 6. City Population and Coffee Consumers  
```sql
SELECT
  c.city_name AS city,
  COUNT(DISTINCT s.customer_id) AS customer_count,
  ROUND(c.population * 0.25) AS estimated_coffe_consumers
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
GROUP BY c.city_name, c.population
ORDER BY estimated_coffe_consumers DESC;
```

### 7. Top Selling Products by City  
```sql
SELECT 
  city_name,
  product_name,
  sales_volume
FROM (
  SELECT 
    c.city_name,
    p.product_name,
    COUNT(s.sale_id) AS sales_volume,
    DENSE_RANK() OVER (PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC) AS rn
  FROM sales s 
  JOIN products p ON s.product_id = p.product_id
  JOIN customers cu ON s.customer_id = cu.customer_id
  JOIN city c ON c.city_id = cu.city_id
  GROUP BY c.city_name, p.product_name
) AS t1
WHERE rn <= 3;
```

### 8. Customer Segmentation by City  
```sql
SELECT 
  c.city_name,
  COUNT(DISTINCT cu.customer_id) AS unique_customers
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
WHERE s.product_id BETWEEN 1 AND 14
GROUP BY c.city_name
ORDER BY c.city_name;
```

### 9. Impact of Estimated Rent on Sales  
```sql
WITH ct AS (
  SELECT
    c.city_name,
    COUNT(DISTINCT s.customer_id) AS customer_count,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sales_per_cust
  FROM city c
  JOIN customers cu ON cu.city_id = c.city_id
  JOIN sales s ON s.customer_id = cu.customer_id
  GROUP BY c.city_name
),
cr AS (
  SELECT city_name, estimated_rent FROM city
)
SELECT 
  ct.city_name,
  ct.customer_count,
  ct.avg_sales_per_cust,
  cr.estimated_rent,
  ROUND(AVG(cr.estimated_rent / ct.customer_count), 2) AS avg_rent_per_cust
FROM ct
JOIN cr ON ct.city_name = cr.city_name
GROUP BY ct.city_name, cr.estimated_rent
ORDER BY avg_rent_per_cust DESC;
```

### 10. Monthly Sales Growth  
```sql
WITH monthly_sales AS (
  SELECT 
    c.city_name,
    MONTH(s.sale_date) AS month,
    YEAR(s.sale_date) AS year,
    SUM(s.total) AS total_sales
  FROM sales s
  JOIN customers cu ON s.customer_id = cu.customer_id
  JOIN city c ON cu.city_id = c.city_id
  GROUP BY c.city_name, MONTH(s.sale_date), YEAR(s.sale_date)
),
gr_ratio AS (
  SELECT 
    city_name,
    month,
    year,
    total_sales AS cr_sales,
    LAG(total_sales, 1) OVER (PARTITION BY city_name ORDER BY city_name, year, month) AS pr_sales
  FROM monthly_sales
)
SELECT 
  city_name,
  month,
  year,
  cr_sales,
  pr_sales,
  ROUND(((cr_sales - pr_sales) / pr_sales) * 100, 2) AS growth_ratio
FROM gr_ratio
WHERE pr_sales IS NOT NULL;
```

### 11. Market Potential Analysis  
```sql
WITH ct AS (
  SELECT
    c.city_name,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sales_per_cust,
    SUM(s.total) AS total_sale
  FROM city c
  JOIN customers cu ON cu.city_id = c.city_id
  JOIN sales s ON s.customer_id = cu.customer_id
  GROUP BY c.city_name
),
cr AS (
  SELECT
    city_name,
    ROUND(population * 0.25) AS estimated_coffee_consumers,
    estimated_rent AS total_rent
  FROM city
)
SELECT 
  ct.city_name,
  ct.total_sale,
  ct.avg_sales_per_cust,
  cr.total_rent,
  ROUND(cr.total_rent / ct.total_customers, 2) AS avg_rent_per_cust,
  ct.total_customers,
  cr.estimated_coffee_consumers
FROM ct
JOIN cr ON ct.city_name = cr.city_name
ORDER BY ct.total_sale DESC;
```

---

## Final Recommendation

### 1. Pune
- **Total Sales:** ₹1.25M  
- **Avg Sales per Customer:** ₹24K  
- **Estimated Coffee Consumers:** 1.87M  
- **Avg Rent per Customer:** Low  
- **Recommendation:** Strong existing performance and low overhead make it ideal for scaling. Consider launching premium offerings here.

### 2. Chennai
- **Total Sales:** ₹0.9M  
- **Estimated Coffee Consumers:** 2.2M  
- **Avg Rent per Customer:** Slightly High  
- **Recommendation:** Large untapped market with high potential. Focus on marketing and acquisition strategies.

### 3. Jaipur
- **Total Sales:** ₹0.8M  
- **Estimated Coffee Consumers:** 1M  
- **Avg Rent per Customer:** Lowest among all cities  
- **Recommendation:** Cost-effective expansion opportunity with low risk and strong customer base potential.

---

## Tech Stack

- **Database:** MySQL  
- **Language:** SQL  
- **Tools Used:** SQL Workbench

---

## Outcomes

The analysis enables the business to:
- Optimize expansion decisions
- Maximize returns by targeting cities with high potential and low overhead
- Develop tailored marketing strategies based on consumer behavior

---


## SQL Files

- [analysis.sql](sql/analysis.sql) – All SQL queries used for data exploration and analysis  
- [schema.sql](sql/schema.sql) – SQL schema defining tables and their structure

---


### Blog
 - Read the full in-depth blog [here](https://medium.com/@adityakumbhar915/brewing-success-a-data-driven-expansion-strategy-for-monday-coffee-2b004d7c9ded).

---
## Credits

Project inspired by real-world business cases and SQL-based data analytics challenges.

