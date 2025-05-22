--Monday Coffee - Data analysis

SELECT * FROM city
SELECT * FROM Customers
SELECT * FROM products
SELECT * FROM sales


--Reports and data analysis
--1) How may people in each city are estimated to consume coffee, given that 25% of the population does ?
SELECT city_name, ROUND((population * 0.25)/100000,2) as Coffee_consumers, city_rank
FROM City
ORDER BY Coffee_consumers DESC

--2)Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
--answer-1
SELECT 
	SUM(total) as Total_revenue
	-- EXTRACT(YEAR FROM sale_date) as Year,
	-- Extract (quarter FROM sale_date) as qtr
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
AND
Extract (quarter FROM sale_date) = 4
--answer-2
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM Sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE 
	EXTRACT(Year FROM s.sale_date) = 2023
	and 
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1




--3)Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT 
	p.product_name,
	COUNT(s.sale_id) as Total_orders
FROM Products P
LEFT JOIN 
sales s ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- 4) Average Sales Amount per City
-- What is the average sales amount per customer in each city?

--City and total sale
--Nor of customers in each these

SELECT 
	ci.city_name,
	SUM(s.total) as Total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_customers,
	SUM(s.total) / COUNT(DISTINCT s.customer_id) AS AVG_sales_per_customer
from sales s
JOIN customers c on c.customer_id = s.customer_id
JOIN City ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 3 DESC

-- 5) City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.


WITH city_table AS
(
	SELECT 
		city_name, 
		ROUND ((Population * 0.25 / 1000000),2) as Coffee_consumers	
	FROM City
),

customer_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) AS Uniqu_customers
	FROM sales s
	JOIN Customers c ON c.customer_id = s.customer_id
	JOIN City ci ON ci.city_id = c.city_id
	GROUP BY 1	
)

SELECT 	
	city_table.city_name,
	city_table.Coffee_consumers AS coffee_consumer_in_millions,
	customer_table.Uniqu_customers AS Unique_Customers
FROM city_table
JOIN 
	customer_table on city_table.city_name = customer_table.city_name

-- 6) Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * FROM
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS total_orders,
		DENSE_RANK () OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC ) as RANK
	FROM sales s
	JOIN Products p ON p.product_id = s.product_id
	JOIN customers c on c.customer_id = s.customer_id
	JOIN city ci ON ci.city_id = c.city_id
	GROUP BY 1,2
) as t1
WHERE rank <=3;
-- ORDER BY 1,3 DESC

-- 7)Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT (Distinct c.customer_id) AS Unique_customers

FROM City ci
LEFT JOIN Customers c ON ci.city_id = c.city_id
JOIN Sales s on s.customer_id = c.customer_id
JOIN Products p on p.product_id = s.product_id
WHERE p.product_id < 14
GROUP BY ci.city_name


-- 8) Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table 
AS
(
	SELECT
		ci.city_name,
		COUNT(DISTINCT s.customer_id) AS total_customers,
		SUM(s.total) / COUNT(DISTINCT s.customer_id) AS Avg_Sales_per_Customer
	FROM Sales s
	JOIN Customers c on c.customer_id = s.customer_id
	JOIN city ci ON ci.city_id = c.city_id
	GROUP BY ci.city_name
	ORDER BY 3 DESC
),
city_rent
AS
(
	SELECT 
		city_name,
		estimated_rent
	FROM city
)
SELECT 
	ct.city_name, 
	ct.total_customers,
	ct.Avg_Sales_per_Customer,
	cr.estimated_rent,
	(cr.estimated_rent / ct.total_customers) AS Avg_rent_per_customers
FROM city_table ct
JOIN city_rent cr ON ct.city_name = cr.city_name
ORDER BY 5 DESC

-- 9) Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH 
monthly_sales AS
(
	SELECT 
		ci.city_name,
		EXTRACT (MONTH FROM sale_date) as month,
		EXTRACT (YEAR FROM sale_date) as year,
		SUM(s.total) as Total_sale
	FROM Sales s 
	JOIN Customers c ON c.customer_id = s.customer_id
	JOIN city ci ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,2,3
),
growth_ratio 
AS
(
	SELECT
		city_name,
		month,
		year,
		total_Sale as cr_month_Sales,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
		FROM monthly_sales
)

SELECT 
	city_name,
	month,
	year,
	cr_month_Sales,
	last_month_sales,
	ROUND(
		(cr_month_sales - last_month_sales)::"numeric" / last_month_sales::"numeric" * 100 , 2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sales is NOT NULL



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

--city, sales, rent, customers, customers*0.25
WITH city_table AS
(
SELECT 
	ci.city_name,
	SUM(s.total) as total_sales,
	COUNT(DISTINCT customer_name) as total_Customers,
	ROUND(SUM(s.total) / COUNT(DISTINCT customer_name), 2) as Avg_sale_per_Customers
FROM sales s
JOIN Customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id 	
GROUP BY 1
ORDER BY 2 DESC
), 
City_rent AS 
(
	SELECT 
		city_name,
		estimated_rent,
		ROUND (Population * 0.25 / 1000000, 2) AS estimated_coffee_consumers
	FROM city
)
SELECT 
	cr.city_name,
	ct.total_sales,
	cr.estimated_rent AS total_rent,
	ct.total_customers,
	estimated_coffee_consumers,
	ct.Avg_sale_per_Customers,
	cr.estimated_rent / ct.total_customers AS Avg_rent_per_Customers
FROM city_table ct
JOIN city_rent cr ON ct.city_name = cr.city_name
ORDER BY 2 DESC	


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.
	4. Customer count is 52 quite good.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Bangalore
	1.Total number of customers are 39 but .average sale per customer is high with just 39 customers.
	2.avg Rent is on the higher side but estimated coffee consumers is 3 million, we can focus a bit on marketing.
	3.Total sales is also with 39 customers, if we focus on bringing more customers bangalore can be more profitable.








