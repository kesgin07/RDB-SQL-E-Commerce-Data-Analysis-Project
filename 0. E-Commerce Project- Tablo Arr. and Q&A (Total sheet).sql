

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

--combined_table tablosuna yeni kolon ekledik
ALTER TABLE #combined_table
ADD  DaysTakenForShipping INT

-- ekleyeceðimiz sorguyu yazdýk
SELECT Ord_ID, Order_Date, Ship_Date,
		DATEDIFF(DAY, Order_Date, Ship_Date) AS DaysTakenForShipping
FROM  #combined_table

-- update iþlemini tamamladýk
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
-- prod_11 ve prod_14 alan müþteriler
SELECT COUNT(*)*1.0 AS #_of_prod11_prod14_orders
FROM #combined_table 
where Prod_ID = 11 or Prod_ID = 14
)
/
(
-- prod_11 ve prod_14 alan müþterilerin toplam sipariþ sayýsý 
SELECT COUNT(Cust_ID)*1.0 AS #_of_orders
FROM #combined_table  AS A
WHERE Cust_ID = ANY (
				SELECT DISTINCT Cust_ID
				FROM #combined_table AS B
				WHERE Prod_ID = 11 or Prod_ID = 14
				)
) as  the_ratio_of_prod11_prod14





--   Customer Segmentation questions below :

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



---yukarýkadi sorguyu geçici tablo üzerinde birleþtirdik 


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

--SONUÇ
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

-- 2009-2012 tarihleri arasýnda veriler var.
-- bazý müþteriler sadece 2009 veya 2010 tarihlerinde bir kaç alýþveriþ yapmýþ. bu



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






--------Month-Wise Retention Rate Question Below :
-- geçici tablo üzerinden iþlemlere devam edeceðim
SELECT DISTINCT A.Cust_ID, YEAR(C.Order_Date) AS years, MONTH(C.Order_Date) AS months
INTO  #combined_table1
FROM  [dbo].[market_fact] AS A, [dbo].[cust_dimen] AS B, [dbo].[orders_dimen] AS C,
	  [dbo].[prod_dimen] AS D, [dbo].[shipping_dimen] AS E
WHERE A.Cust_ID = B.Cust_ID AND A.Ord_ID = C.Ord_ID AND A.Prod_ID = D.Prod_ID AND A.Ship_ID = E. Ship_ID

-- AYLARA GÖRE MÜÞTERÝ SAYISINI ÇIKARDIK
SELECT DISTINCT  years, months, COUNT(Cust_ID) OVER (PARTITION BY years, months order by years, months)
FROM #combined_table1
ORDER BY years, months




----- Soruyu Aþaðýdaki formüle göre hesapladým -----
-- (Dönem sonu müþteri sayýsý - Dönem içi elde edilen yeni müþteri sayýsý) / Dönem baþý müþteri sayýsý X 100




-- Dönem içi elde edilen yeni müþteri sayýsýný hesaplarken 'except' kullandým.
-- [ Mevcut ayýn (benzersiz) müþteri sayýsý] - [ bir önceki ayýn (benzersiz) müþteri sayýsý ] ile kaç tane yeni müþteri geldiðini hesapladým
-- Daha sonra bu formülü kullanacaðýz 
DECLARE @AY INT = 1 , @YIL  INT =2009
 WHILE @YIL < 2013
 BEGIN
	IF @AY < 12
	begin
		
		select distinct  COUNT (distinct  Cust_ID) as fark from  #combined_table1 where Cust_ID =any (
		SELECT DISTINCT  Cust_ID
		FROM #combined_table1
		WHERE years =@YIL AND  months =@AY+1

		except 

		SELECT DISTINCT  Cust_ID
		FROM #combined_table1
		WHERE years =@YIL AND  months =@AY )
		
		SET @AY += 1

		end
	ELSE IF @AY = 12
	begin
	
		select distinct  COUNT (distinct  Cust_ID) as fark from  #combined_table1 where Cust_ID =any (
		SELECT DISTINCT  Cust_ID
		FROM #combined_table1
		WHERE years =@YIL+1 AND  months =1

		except 

		SELECT DISTINCT  Cust_ID
		FROM #combined_table1
		WHERE years =@YIL AND  months =@AY )
		
		SET @AY =1
		SET @YIL += 1
		
	end
END






--- Month-Wise Retention Rate-- müþteri elde tutma oranýnýn formülü ---
-- Önce formülü aþagýdaki gibi kurgulayýp buldum
DECLARE @AY INT = 1 , @YIL  INT =2009
 WHILE @YIL < 2013
 BEGIN
	IF @AY < 12
	BEGIN

		SELECT (
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY +1
		)
		- 
		(
		SELECT COUNT(DISTINCT  Cust_ID) FROM #combined_table1 WHERE Cust_ID = ANY (  SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months = @AY +1

																					except 

																					SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months =@AY)
		)) * 100.0 /
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY
		)))
		
		SET @AY += 1

	END

	ELSE IF @AY = 12
	BEGIN

		SELECT (
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL+1 AND months = 1
		)
		- 
		(
		SELECT COUNT(DISTINCT  Cust_ID) FROM #combined_table1 WHERE Cust_ID = ANY (  SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL+1 AND  months = 1

																					except 

																					SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months =@AY)
		)) * 100.0 /
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY
		)))
		
		SET @AY =1
		SET @YIL += 1	
		
	END
END









--- Yukarýdaki sorgularý geçici bir tabloda birleþtirip sonuca bakacaðýz   ---


CREATE TABLE #Retention_Rate
(	
	[years] INT,
	[months] INT,
	[Retention_Rate] FLOAT	
)



DECLARE @AY INT = 1 , @YIL  INT =2009
 WHILE @YIL < 2013
 BEGIN
	IF @AY < 12
	BEGIN
		INSERT INTO #Retention_Rate (years, months, Retention_Rate)
		VALUES (@YIL, @AY, (
		SELECT (
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY +1
		)
		- 
		(
		SELECT COUNT(DISTINCT  Cust_ID) FROM #combined_table1 WHERE Cust_ID = ANY (  SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months = @AY +1

																					except 

																					SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months =@AY)
		)) * 100.0 /
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY
		)))))
		
		SET @AY += 1

	END

	ELSE IF @AY = 12
	BEGIN
		INSERT INTO #Retention_Rate (years, months, Retention_Rate)
		VALUES (@YIL, @AY, (
		SELECT (
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL+1 AND months = 1
		)
		- 
		(
		SELECT COUNT(DISTINCT  Cust_ID) FROM #combined_table1 WHERE Cust_ID = ANY (  SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL+1 AND  months = 1

																					except 

																					SELECT DISTINCT  Cust_ID
																					FROM #combined_table1
																					WHERE years =@YIL AND  months =@AY)
		)) * 100.0 /
		((SELECT COUNT(DISTINCT Cust_ID)
		FROM #combined_table1
		WHERE years = @YIL AND months = @AY
		)))))
		
		SET @AY =1
		SET @YIL += 1	
		
	END
END



-- CEVAP

SELECT *
FROM #Retention_Rate














