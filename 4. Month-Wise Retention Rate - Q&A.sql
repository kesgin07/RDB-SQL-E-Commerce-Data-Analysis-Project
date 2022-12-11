
--------Month-Wise Retention Rate 
-- Find month by month customer retention rate since the start of the business?

-- I will continue operations through the temporary table
SELECT DISTINCT A.Cust_ID, YEAR(C.Order_Date) AS years, MONTH(C.Order_Date) AS months
INTO  #combined_table1
FROM  [dbo].[market_fact] AS A, [dbo].[cust_dimen] AS B, [dbo].[orders_dimen] AS C,
	  [dbo].[prod_dimen] AS D, [dbo].[shipping_dimen] AS E
WHERE A.Cust_ID = B.Cust_ID AND A.Ord_ID = C.Ord_ID AND A.Prod_ID = D.Prod_ID AND A.Ship_ID = E. Ship_ID

-- I found the number of customers by month
SELECT DISTINCT  years, months, COUNT(Cust_ID) OVER (PARTITION BY years, months order by years, months)
FROM #combined_table1
ORDER BY years, months


----- Calculation was made using the formula below:
-- (Number of customers at the end of the period - Number of new customers acquired during the period)
--  / Number of customers at the beginning of the period X 100

-- I used 'except' when calculating the number of new customers acquired during the period.
-- I calculated how many new customers arrived with formul below :
-- [ current month's (unique) customer count] - [ previous month's (unique) customer count ]
-- I will use this formula later

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



--- Month-Wise Retention Rate
-- First, I set up the formula as follows and found it.
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




--- We will combine the above queries into a temporary table and see the result


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



-- Answer

SELECT *
FROM #Retention_Rate