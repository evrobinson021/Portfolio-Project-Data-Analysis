## Market Segmentation Analysis

## Analyse cost ranges across the products
    
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