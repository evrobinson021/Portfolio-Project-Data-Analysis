/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

	## Drop and recreate the 'DataWarehouseAnalytics' database

DROP DATABASE IF EXISTS DataWarehouseAnalytics;

	## Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;

USE DataWarehouseAnalytics;

	## Create Schemas

CREATE SCHEMA gold;

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);

TRUNCATE TABLE gold.dim_customers;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/dim_customers.csv'
INTO TABLE gold.dim_customers
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	customer_key,
	customer_id,
	customer_number,
	first_name,
	last_name,
	country,
	marital_status,
	gender,
	birthdate,
	create_date
)
SET birthdate = NULLIF(@birthdate, '');

TRUNCATE TABLE gold.dim_products;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/dim_products.csv'
INTO TABLE gold.dim_products
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
    IGNORE 1 ROWS
    ;

TRUNCATE TABLE gold.fact_sales;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/fact_sales.csv'
INTO TABLE gold.fact_sales
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\n'
    IGNORE 1 ROWS
    ;

	## Changes Over Time Analysis - The below table shows the total number of sales and customers each Month

SELECT 
	DATE_FORMAT(order_date, '%Y-%m') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(distinct customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_date;

	## Cumulative Analysis -Total Sales for each Month and the running sales over time

SELECT
	order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM 
(
SELECT 
	DATE_FORMAT(order_date, '%Y-%m') AS order_date,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) AS monthly_sales;

	## Finding the average number of total sales annualy

SELECT
	order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	ROUND(AVG(avg_price) OVER (ORDER BY order_date), 2) AS moving_average
FROM 
(
SELECT 
	DATE_FORMAT(order_date, '%Y') AS order_date,
    SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y')
) AS monthly_sales;

	## Performance Analysis
	## Analyise the annual performance of products by comparing the products current sales against the average sales performance and the previous years sales.

	## Current Sales vs Average Sales Performance
    
WITH yearly_product_sales AS (
SELECT
    YEAR(order_date) AS order_year,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(order_date), p.product_name
)
SELECT
	order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS avg_sales,
    current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS difference_in_avg,
CASE 
	WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) > 0 THEN 'Above Avg'
    WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) < 0 THEN 'Below Avg'
    ELSE 'Avg'
END avg_change
FROM yearly_product_sales
ORDER BY product_name, order_year;


	## Current Sales vs Previous Years Performance
    
WITH yearly_product_sales AS (
SELECT
    YEAR(order_date) AS order_year,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(order_date), p.product_name
)
SELECT
	order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS avg_sales,
    current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS difference_in_avg,
CASE 
	WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) > 0 THEN 'Above Avg'
    WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) < 0 THEN 'Below Avg'
    ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS difference_in_previous_year,
CASE 
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
    WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
    ELSE 'No Change'
END previous_year_comparison
FROM yearly_product_sales
ORDER BY product_name, order_year;

	## Analysing which categories contributed the most to overall sales
    
WITH category_sales AS
(
SELECT
	category,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY category
)
SELECT 
	category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((total_sales / SUM(total_sales) OVER ())*100,2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

	## Product Segmentation - Analyse cost ranges across the products
    
WITH product_segments AS
(
SELECT
	product_key,
    product_name,
    cost,
CASE 
	WHEN cost < 100 THEN 'Below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
    WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
    ELSE 'Above 1000'
END cost_range
FROM gold.dim_products
)
SELECT
	cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

	## Grouping customers based on their spending habits
    
WITH customer_spending AS
(
SELECT
	c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS customer_lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT
	customer_key,
    total_spending,
    customer_lifespan,
    CASE 
		WHEN customer_lifespan > 12 AND total_spending > 5000 THEN 'VIP'
        WHEN customer_lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		ELSE 'New'
	END customer_segment
    FROM customer_spending;

	## Calculating the total number of customers for each lifespan segment
    
WITH customer_spending AS
(
SELECT
	c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS customer_lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM (
SELECT
	customer_key,
    CASE 
		WHEN customer_lifespan > 12 AND total_spending > 5000 THEN 'VIP'
        WHEN customer_lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment
FROM customer_spending 
) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
=============================================================
Customer Reports
=============================================================
Script Purpose:
	- This report consolidates key customer metrics and behaviours
        
Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and ages groups.
    3. Aggregates customer-level metrics:
		- total orders
        - total sales
        - total quality purchased
        - total products
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
        - average order value
        - average monthly spend
	=============================================================
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS 
(
/*=============================================================
 1) Base Query: Retrieves core columns from tables
===============================================================*/
SELECT
	f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    FLOOR(DATEDIFF(CURDATE(), c.birthdate)/365) AS customer_age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key
WHERE f.order_date IS NOT NULL
)
, customer_aggregation 	AS (
/*=======================================================================
 2) Customer Aggregations: Summarises key metrics at the customer level
=========================================================================*/
SELECT 
	customer_key,
    customer_number,
    customer_name,
    customer_age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(MONTH,MIN(order_date),MAX(order_date)) AS customer_lifespan
FROM base_query
GROUP BY 
	customer_key,
    customer_number,
    customer_name,
    customer_age
    )
SELECT
	customer_key,
    customer_number,
    customer_name,
    customer_age,
    CASE 
		 WHEN customer_age < 20 THEN 'Under 20'
		 WHEN customer_age BETWEEN 20 AND 29 THEN '20 - 29'
         WHEN customer_age BETWEEN 30 AND 39 THEN '30 - 39'
         WHEN customer_age BETWEEN 40 AND 49 THEN '40 - 49'
		 ELSE '50+'
	END AS age_group,
	CASE 
		WHEN customer_lifespan > 12 AND total_sales > 5000 THEN 'VIP'
        WHEN customer_lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
    last_order_date,
    TIMESTAMPDIFF(MONTH, last_order_date, CURDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    customer_lifespan,
## Compute average order value (AVO)
	CASE
		WHEN total_sales = 0 THEN 0
		ELSE ROUND(total_sales / total_orders) 
	END AS avg_order_value,
## Compute average monthly spend
	CASE
		WHEN customer_lifespan = 0 THEN total_sales
		ELSE ROUND(total_sales / customer_lifespan) 
	END AS avg_monthly_spend	
FROM customer_aggregation;

/*
=======================================================================
Product Reports
=======================================================================
Script Purpose:
	- This report consolidates key product metrics and behaviours
        
Highlights:
	1. Gathers essential fields such as product name, category, subcategory and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
		- total orders
        - total sales
        - total quality sold
        - total customers (unique)
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
	=======================================================================
*/
CREATE VIEW gold.report_products AS
WITH base_query AS 
(
/*=======================================================================
 1) Base Query: Retrieves core columns from fact_sales and dim_products
=========================================================================*/
SELECT
	f.order_number,
    f.order_date,
    f.customer_key,
    f.sales_amount,
    f.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL ## Only consider valid sales dates
)
, product_aggregation 	AS 
(
/*=======================================================================
 2) Product Aggregations: Summarises key metrics at the product level
=========================================================================*/
SELECT 
	product_key,
    product_name,
    category,
    subcategory,
    cost,
    TIMESTAMPDIFF(MONTH,MIN(order_date),MAX(order_date)) AS product_lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price 
FROM base_query
GROUP BY 
	product_key,
    product_name,
    category,
    subcategory,
    cost
)
/*=======================================================================
 3) Final Query: Combines all product results into one output
=========================================================================*/
SELECT
	product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
    CASE 
		 WHEN total_sales > 50000 THEN 'High Performer' 
		 WHEN total_sales >= 50000 THEN 'Mid-Range'
		 ELSE 'Low Performer'
	END AS product_segment,
	product_lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
## Average order revenue (AOR)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE ROUND(total_sales / total_orders) 
	END AS avg_order_revenue,
## Average monthly revenue
	CASE
		WHEN product_lifespan = 0 THEN total_sales
		ELSE ROUND(total_sales / product_lifespan) 
	END AS avg_monthly_revenue	
FROM product_aggregation;
