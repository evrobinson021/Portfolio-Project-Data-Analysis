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