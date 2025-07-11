USE monday_coffee_db;

-- Reports & Analysis

-- Q1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population?
SELECT 
city_name,
ROUND(population * 0.25) as coffee_consumers,
city_rank
FROM city
ORDER BY coffee_consumers DESC;

-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in last qtr of 2023?
SELECT
    YEAR(sale_date) AS year,
    QUARTER(sale_date) AS quarter,
    SUM(total) AS total_sales
FROM sales
WHERE QUARTER(sale_date) = 4 AND YEAR(sale_date) = 2023
GROUP BY
    YEAR(sale_date),
    QUARTER(sale_date);
    
SELECT
	c.city_name as city,
    SUM(s.total) as total_sales
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
WHERE QUARTER(sale_date) = 4 AND YEAR(sale_date)= 2023
GROUP BY
c.city_name
ORDER BY total_sales DESC limit 5;

-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
p.product_name,
COUNT(s.product_id) as units_sold from sales s
LEFT JOIN 
products p ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY units_sold DESC;

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT
	c.city_name as city,
    COUNT(DISTINCT s.customer_id) as customer_count,
    ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sales_per_cust
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
GROUP BY
c.city_name
ORDER BY avg_sales_per_cust DESC;

-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
SELECT
	c.city_name as city,
    COUNT(DISTINCT s.customer_id) as customer_count,
    ROUND(c.population*0.25) as estimated_coffe_consumers
FROM city c
JOIN customers cu ON cu.city_id = c.city_id
JOIN sales s ON s.customer_id = cu.customer_id
GROUP BY
c.city_name, c.population
ORDER BY estimated_coffe_consumers DESC;

-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT 
  city_name,
  product_name,
  sales_volume
FROM
(
SELECT 
	c.city_name,
    p.product_name,
    COUNT(s.sale_id) as sales_volume,
		DENSE_RANK() OVER ( PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC) as rn
	FROM
	sales s 
	JOIN products p
	ON s.product_id = p.product_id
	JOIN customers cu
	ON s.customer_id = cu.customer_id
	JOIN city c
	ON c.city_id = cu.city_id
	GROUP BY 
	c.city_name,p.product_name
) as t1
WHERE rn <= 3;



-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
  c.city_name,
  COUNT(DISTINCT cu.customer_id) AS unique_customers
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
WHERE s.product_id BETWEEN 1 AND 14
GROUP BY c.city_name
ORDER BY c.city_name;


-- Impact of estimated rent on sales:
-- Find each city and their average sale per customer and avg rent per customer

WITH
ct 
AS(
	SELECT
		c.city_name,
		COUNT(DISTINCT s.customer_id) as customer_count,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sales_per_cust
	FROM city c
	JOIN customers cu ON cu.city_id = c.city_id
	JOIN sales s ON s.customer_id = cu.customer_id
	GROUP BY
	c.city_name
	ORDER BY avg_sales_per_cust DESC
),
cr
AS 
(
	SELECT
		city_name,
        estimated_rent
        FROM city
)
SELECT 
	ct.city_name,
    ct.customer_count,
    ct.avg_sales_per_cust,
    cr.estimated_rent,
    ROUND(AVG(cr.estimated_rent/ct.customer_count),2) as avg_rent_per_cust
FROM 
	ct JOIN cr ON ct.city_name = cr.city_name
    GROUP BY 
	ct.city_name, cr.estimated_rent
ORDER BY 
avg_rent_per_cust DESC;
  


-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH 
monthly_sales
AS(
	SELECT 
		c.city_name,
		MONTH(s.sale_date) as month,
		YEAR(s.sale_date) as year,
		SUM(s.total) as total_sales
	FROM 
	sales s
	JOIN customers cu ON s.customer_id = cu.customer_id
	JOIN city c ON cu.city_id = c.city_id
	GROUP BY
		c.city_name,
		MONTH(s.sale_date),
		YEAR(s.sale_date)
	ORDER BY
		c.city_name,YEAR(s.sale_date),MONTH(s.sale_date)
)
,
gr_ratio
AS
(
	SELECT 
		city_name,
		month,
		year,
		total_sales as cr_sales,
		LAG(total_sales,1) OVER(PARTITION BY city_name ORDER BY city_name,year,month) as pr_sales
	FROM 
		monthly_sales
)


SELECT 
	city_name,
		month,
		year,
        cr_sales,
        pr_sales,
        ROUND(((cr_sales-pr_sales)/pr_sales)*100,2) as growth_ratio
FROM
	gr_ratio
WHERE
	pr_sales IS NOT NULL;
        
        

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
 
 
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


-- Recommendation
/*
	1. Pune
		- Total Sales: ₹1.25M
		- Average Sales per Customer: ₹24K
		- Average Rent per Customer: Relatively low
		- Estimated Coffee Consumers: 1.87M
	Recommendation: 
		Strong existing performance with low overhead. Continue scaling and consider introducing premium offerings.

	2. Chennai

		- Total Sales: ₹0.9M
		- Average Rent per Customer: Slightly high
		- Estimated Coffee Consumers: 2.2M
		Recommendation: 
        High potential for growth. Invest in marketing and customer acquisition to tap into the large consumer base.

	3. Jaipur

		- Total Sales: ₹0.8M
		- Average Rent per Customer: Lowest among all
		- Estimated Coffee Consumers: 1M
		Recommendation: 
        Cost-effective city with a sizable untapped market. Ideal for expanding operations with low-risk investment.
*/

