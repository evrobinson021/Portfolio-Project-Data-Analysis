## Performance Analysis
## Analyse the annual performance of products by comparing the products current sales against the average sales performance and the previous years sales.

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