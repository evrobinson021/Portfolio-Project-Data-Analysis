## Time Series Analysis - The below query shows the total number of sales and customers each month

SELECT 
	DATE_FORMAT(order_date, '%Y-%m') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(distinct customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_date;