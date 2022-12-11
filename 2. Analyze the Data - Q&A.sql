
--Analyze the data by finding the answers to the questions below:
-- 1. Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, “prod_dimen”, 
--    “shipping_dimen”, Create a new table, named as “combined_table”.


SELECT A.*, B.Customer_Name, B.Customer_Segment, B.Province, B.Region,
			C.Order_Date,C.Order_Priority, D.Product_Category, D.Product_Sub_Category,
			E.Order_ID, E.Ship_Date, E.Ship_Mode
INTO #combined_table
FROM  [dbo].[market_fact] AS A, [dbo].[cust_dimen] AS B, [dbo].[orders_dimen] AS C,
	  [dbo].[prod_dimen] AS D, [dbo].[shipping_dimen] AS E
WHERE A.Cust_ID = B.Cust_ID AND A.Ord_ID = C.Ord_ID AND A.Prod_ID = D.Prod_ID AND A.Ship_ID = E. Ship_ID


SELECT *
FROM #combined_table


-- 2. Find the top 3 customers who have the maximum count of orders.


SELECT TOP(3) B.Cust_ID, B.Customer_Name, COUNT(Ord_ID) AS number_od_orders
FROM [dbo].[market_fact] AS A, [dbo].[cust_dimen] AS B
WHERE A.Cust_ID = B.Cust_ID
GROUP BY B.Cust_ID, B.Customer_Name
ORDER BY COUNT(Ord_ID) DESC



-- 3. Create a new column at combined_table as DaysTakenForShipping that contains 
--    the date difference of Order_Date and Ship_Date.

--I added a new column to the combined_table table
ALTER TABLE #combined_table
ADD  DaysTakenForShipping INT

-- I wrote the query to add
SELECT Ord_ID, Order_Date, Ship_Date,
		DATEDIFF(DAY, Order_Date, Ship_Date) AS DaysTakenForShipping
FROM  #combined_table

-- We have completed the update
UPDATE #combined_table 
SET DaysTakenForShipping = B.DaysTakenForShipping
FROM #combined_table AS A
INNER JOIN (SELECT Ord_ID, Order_Date, Ship_Date,
			DATEDIFF(DAY, Order_Date, Ship_Date) AS DaysTakenForShipping
			FROM  #combined_table) AS B
ON A.Ord_ID = B.Ord_ID


SELECT *
FROM #combined_table


-- 4. Find the customer whose order took the maximum time to get shipping.

SELECT   Order_ID, Cust_ID, Customer_Name, Order_Date, Ship_Date,
		MAX(DaysTakenForShipping) OVER(ORDER BY DaysTakenForShipping DESC) AS max_time_shipping
FROM #combined_table


-- 5. Count the total number of unique customers in January and how many of them came
--     back every month over the entire year in 2011


SELECT MONTH(Order_Date) AS Months,
      DATENAME(MONTH,Order_Date) AS Month_name,
	  COUNT(DISTINCT cust_ID) AS #_of_cust
FROM #combined_table AS A
WHERE   EXISTS (
				SELECT DISTINCT cust_ID
				FROM #combined_table AS B
				WHERE MONTH(Order_Date) = 1
				AND YEAR(Order_Date)=2011
				AND A.Cust_ID = B.Cust_ID
			  )
AND YEAR(Order_Date)=2011
GROUP BY MONTH(Order_Date) , DATENAME(MONTH,Order_Date)
ORDER by Months


--  6. Write a query to return for each user the time elapsed between the first
--     purchasing and the third purchasing, in ascending order by Customer ID.


WITH T1 AS (
SELECT  DISTINCT Cust_ID ,Order_Date,
		DENSE_RANK() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS number_of_orders
FROM #combined_table  
), T2 AS (
SELECT  DISTINCT Cust_ID ,
		CONVERT(DATE , FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Order_Date )) AS first_purchasing,
		CONVERT(DATE , FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Order_Date DESC)) AS third_purchasing
FROM T1
WHERE number_of_orders IN (1,2,3)
)
SELECT *, DATEDIFF (DAY, first_purchasing , third_purchasing) AS time_elapsed_DAYS
FROM T2
ORDER BY Cust_ID


--   7. Write a query that returns customers who purchased both product 11 and
--       product 14, as well as the ratio of these products to the total number of
--       products purchased by the customer.


select  
(
-- Customers purchasing prod_11 and prod_14
SELECT COUNT(*)*1.0 AS #_of_prod11_prod14_orders
FROM #combined_table 
where Prod_ID = 11 or Prod_ID = 14
)
/
(
-- Total number of orders from customers purchasing prod_11 and prod_14
SELECT COUNT(Cust_ID)*1.0 AS #_of_orders
FROM #combined_table  AS A
WHERE Cust_ID = ANY (
				SELECT DISTINCT Cust_ID
				FROM #combined_table AS B
				WHERE Prod_ID = 11 or Prod_ID = 14
				)
) as  the_ratio_of_prod11_prod14



