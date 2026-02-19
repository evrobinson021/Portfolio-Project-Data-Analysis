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
