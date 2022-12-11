SELECT A.*, B.Customer_Name, B.Customer_Segment, B.Province, B.Region,
			C.Order_Date,C.Order_Priority, D.Product_Category, D.Product_Sub_Category,
			E.Order_ID, E.Ship_Date, E.Ship_Mode
INTO #combined_table
FROM  [dbo].[market_fact] AS A, [dbo].[cust_dimen] AS B, [dbo].[orders_dimen] AS C,
	  [dbo].[prod_dimen] AS D, [dbo].[shipping_dimen] AS E
WHERE A.Cust_ID = B.Cust_ID AND A.Ord_ID = C.Ord_ID AND A.Prod_ID = D.Prod_ID AND A.Ship_ID = E. Ship_ID


SELECT Cust_ID, Order_Date
FROM #combined_table
ORDER BY 1


----------------   Customer Segmentation  -------------------
-- 1. Create a “view” that keeps visit logs of customers on a monthly basis. 
--  (For each log, three field is kept: Cust_id, Year, Month)
SELECT Cust_ID,YEAR(Order_Date) AS years, MONTH(Order_Date) as months
FROM #combined_table
GROUP BY Cust_ID, YEAR(Order_Date), MONTH(Order_Date)
ORDER BY 1,2


--2  Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)
SELECT Cust_ID,YEAR(Order_Date) AS years, MONTH(Order_Date) as months, COUNT(Order_ID) AS num_of_visit
FROM #combined_table
GROUP BY Cust_ID, YEAR(Order_Date), MONTH(Order_Date)
ORDER BY 1

-- or 


SELECT *
FROM (SELECT Cust_ID,YEAR(Order_Date) AS years, MONTH(Order_Date) as months
FROM #combined_table
)AS A
PIVOT (
	COUNT(months) 
	FOR months
	IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]   )
)AS PVT_TBL
ORDER BY Cust_ID


-- 3  For each visit of customers, create the next month of the visit as a separate column.


DECLARE @YIL INT = 2009 

WHILE @YIL < 2013
BEGIN
	
		SELECT *
		FROM (
		SELECT Cust_ID,YEAR(Order_Date) AS years, MONTH(Order_Date) as months
		FROM #combined_table
		WHERE YEAR(Order_Date) = @YIL  )  AS A
		PIVOT (
			COUNT(months) 
			FOR months
			IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]   )
		)AS a
		
		
		SET @YIL += 1	
		
END 



---I combined above query on temp table


CREATE TABLE #DENEME
(
	Cust_ID INT,
	years INT,
	[1] INT, [2] INT, [3] INT, [4] INT, [5] INT, [6] INT, [7] INT, [8] INT, [9] INT, [10] INT, [11] INT, [12]  INT
)


DECLARE @YIL INT = 2009 

WHILE @YIL < 2013
BEGIN
		INSERT INTO #DENEME
		SELECT *
		FROM (
		SELECT Cust_ID,YEAR(Order_Date) AS years, MONTH(Order_Date) as months
		FROM #combined_table
		WHERE YEAR(Order_Date) = @YIL  )  AS A
		PIVOT (
			COUNT(months) 
			FOR months
			IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]   )
		)AS a
		
		
		SET @YIL += 1	
		
END 


SELECT *
FROM #DENEME
ORDER BY Cust_ID, years


-- 4 Calculate the monthly time gap between two consecutive visits by each customer.


WITH T1 AS (
SELECT DISTINCT Cust_ID, Order_Date
FROM #combined_table
), T2 AS (
SELECT *,
		LAG(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Order_Date)  AS previous_order_date
FROM T1
)
SELECT *,
		DATEDIFF(MONTH, previous_order_date, Order_Date ) AS orders_time_gap
FROM T2


-- 5  Categorise customers using average time gaps. Choose the most fitted labeling model for you.

-- There are Data between 2009 and 2012.
-- some customers only made a few purchases in 2009 or 2010

WITH T1 AS (
SELECT DISTINCT Cust_ID, Order_Date
FROM #combined_table
), T2 AS (
SELECT *,
		LAG(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Order_Date)  AS previous_order_date
FROM T1
), T3 AS (
SELECT Cust_ID,
		AVG( DATEDIFF(MONTH, previous_order_date, Order_Date )) AS average_time_gaps
FROM T2
GROUP BY Cust_ID
)
SELECT *, CASE
		WHEN average_time_gaps IS NULL THEN 'churn'
		WHEN average_time_gaps < 6 THEN 'regular'
		WHEN average_time_gaps < 12 THEN 'poor regular'
		WHEN average_time_gaps >= 12 THEN 'irregular'
		ELSE 'other'

		END AS Customer_regularity 
FROM T3


