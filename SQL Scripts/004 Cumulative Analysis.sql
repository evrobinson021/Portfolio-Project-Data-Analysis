## Cumulative Analysis -Total sales for each month and the running sales over time

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