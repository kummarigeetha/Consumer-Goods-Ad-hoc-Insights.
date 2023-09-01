--  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select  DISTINCT market FROM dim_customer WHERE customer="Atliq Exclusive" AND region="APAC";

-- What is the percentage of unique product increase in 2021 vs. 2020? 
/*The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

 WITH unique_product_count AS(
 SELECT COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN product_code END) AS unique_products_2020,
 COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN product_code END) AS unique_products_2021 FROM fact_sales_monthly)
 SELECT  unique_products_2020,unique_products_2021,
 ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100 ,2)AS percentage_change
 FROM unique_product_count;
 
 -- Provide a report with all the unique product counts for each segment and 
-- sort them in descending order of product counts.
    /*The final output contains
2 fields,
segment
product_count */ 

SELECT segment,COUNT(DISTINCT(product_code)) AS product_code
FROM dim_product
GROUP BY segment
ORDER BY product_code DESC;

--  Which segment had the most increase in unique products in 2021 vs 2020?
/* The final output contains these fields,
segment
product_count_2020
product_count_2021
difference  */

WITH unique_products AS(
SELECT p.segment AS segment,COUNT(DISTINCT (CASE WHEN fiscal_year=2020 THEN a.product_code END))AS product_count_2020,
count(DISTINCT (CASE WHEN fiscal_year=2021 THEN a.product_code END)) AS product_count_2021 FROM
fact_sales_monthly AS a INNER JOIN dim_product AS p 
ON a.product_code=p.product_code
GROUP BY p.segment)
SELECT segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020) AS difference
FROM unique_products
ORDER BY difference DESC;

-- Get the products that have the highest and lowest manufacturing costs.
/* The final output should contain these fields,
product_code
product
manufacturing_cost */

SELECT m.product_code,p.product,m.manufacturing_cost FROM dim_product AS p
INNER JOIN fact_manufacturing_cost AS m 
ON p.product_code=m.product_code
WHERE m.manufacturing_cost=(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
OR
 m.manufacturing_cost=(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
 ORDER BY m.manufacturing_cost DESC;
 
 /* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */ 

SELECT f.customer_code,d.customer,ROUND(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
FROM dim_customer AS d 
INNER JOIN fact_pre_invoice_deductions AS f 
ON d.customer_code=f.customer_code
WHERE fiscal_year="2021" AND market="India"
GROUP BY customer, customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount  */

SELECT MONTHNAME(f.date)AS month_name,year(f.date) AS year,
ROUND(SUM(sold_quantity*gross_price),2) AS gross_sales_amount
FROM fact_sales_monthly AS f 
JOIN dim_customer AS  d 
ON f.customer_code=d.customer_code
JOIN fact_gross_price fa 
ON f.product_code=fa.product_code
WHERE d.customer="Atliq Exclusive"
GROUP BY  month_name,year;

/* In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity  */

SELECT CASE
WHEN MONTH(date) IN (9,10,11) THEN "Q1"
WHEN MONTH(date) IN (12,1,2) THEN "Q2"
WHEN MONTH(date) IN (3,4,5) THEN "Q3"
ELSE "Q4"
END AS quarters,
SUM(sold_quantity) AS total_quantity_sold
FROM fact_sales_monthly 
WHERE fiscal_year="2020"
GROUP BY quarters
ORDER BY total_quantity_sold DESC;

/* Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage  */

WITH cte AS (
SELECT C.channel,
       ROUND(SUM(G.gross_price*FS.sold_quantity/1000000), 2) AS Gross_sales_mln
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE FS.fiscal_year = 2021
GROUP BY channel
)
SELECT channel,Gross_sales_mln,CONCAT(ROUND(Gross_sales_mln*100/total,2),"%") AS percentage
FROM 
(
(SELECT SUM(Gross_sales_mln) AS total FROM cte) A,
(SELECT * FROM cte) B
) 
ORDER BY percentage DESC;

/* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order  */
WITH Output1 AS 
(
SELECT P.division, FS.product_code, P.product, SUM(FS.sold_quantity) AS Total_sold_quantity
FROM dim_product P JOIN fact_sales_monthly FS
ON P.product_code = FS.product_code
WHERE FS.fiscal_year = 2021 
GROUP BY  FS.product_code, division, P.product
),
Output2 AS 
(
SELECT division, product_code, product, Total_sold_quantity,
        RANK() OVER(PARTITION BY division ORDER BY Total_sold_quantity DESC) AS 'Rank_Order' 
FROM Output1
)
 SELECT Output1.division, Output1.product_code, Output1.product, Output2.Total_sold_quantity, Output2.Rank_Order
 FROM Output1 JOIN Output2
 ON Output1.product_code = Output2.product_code
WHERE Output2.Rank_Order IN (1,2,3)