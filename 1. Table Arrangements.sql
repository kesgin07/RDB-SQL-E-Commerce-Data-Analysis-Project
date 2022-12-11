
ALTER TABLE [Book].[Book]  WITH CHECK ADD  CONSTRAINT [FK_Publisher] FOREIGN KEY([Publisher_ID])
REFERENCES [Book].[Publisher] ([Publisher_ID])


-- Edits for the cust_dimen table

Select *
from [dbo].[cust_dimen]

-- We edited the Cust_ID column to show only customer numbers and set the data type as int

UPDATE [dbo].[cust_dimen] SET  Cust_ID = TRIM('Cust_' FROM Cust_ID)


ALTER TABLE [dbo].[cust_dimen]
ALTER COLUMN Cust_ID INT NOT NULL 

ALTER TABLE [dbo].[cust_dimen]
ADD PRIMARY KEY (Cust_ID )


-- Edits for the market_fact table


Select *
from [dbo].[market_fact]


UPDATE [dbo].[market_fact] SET  Cust_ID = TRIM('Cust_' FROM Cust_ID)

UPDATE [dbo].[market_fact] SET  Prod_ID = TRIM('Prod_' FROM Prod_ID)

UPDATE [dbo].[market_fact] SET  Ord_ID = TRIM('Ord_' FROM Ord_ID)

UPDATE [dbo].[market_fact] SET  Ship_ID = TRIM('Ship_' FROM Ship_ID)


ALTER TABLE [dbo].[market_fact]
ALTER COLUMN [Cust_ID] INT NOT NULL 

ALTER TABLE [dbo].[market_fact]
ALTER COLUMN Prod_ID INT NOT NULL 

ALTER TABLE [dbo].[market_fact]
ALTER COLUMN Ship_ID INT NOT NULL 

ALTER TABLE [dbo].[market_fact]
ALTER COLUMN Ord_ID INT  NOT NULL 

ALTER TABLE [dbo].[market_fact]
ADD CONSTRAINT PK_market_fact PRIMARY KEY (Ord_ID,Ship_ID, Prod_ID, Cust_ID);


ALTER TABLE [dbo].[market_fact] WITH CHECK  ADD  CONSTRAINT [FK_Cust] FOREIGN KEY(Cust_ID)
REFERENCES [dbo].[cust_dimen] (Cust_ID)

ALTER TABLE [dbo].[market_fact] WITH CHECK  ADD  CONSTRAINT [FK_Prod] FOREIGN KEY(Prod_ID)
REFERENCES [dbo].[prod_dimen] (Prod_ID)

ALTER TABLE [dbo].[market_fact] WITH CHECK  ADD  CONSTRAINT [FK_Ord] FOREIGN KEY(Ord_ID)
REFERENCES [dbo].[orders_dimen] (Ord_ID)

ALTER TABLE [dbo].[market_fact] WITH CHECK  ADD  CONSTRAINT [FK_Ship] FOREIGN KEY(Ship_ID)
REFERENCES [dbo].[shipping_dimen] (Ship_ID)


-- Edits for the orders_dimen table


Select *
from [dbo].[orders_dimen]



UPDATE [dbo].[orders_dimen] SET  Ord_ID = TRIM('Ord_' FROM Ord_ID)

ALTER TABLE [dbo].[orders_dimen] 
ALTER COLUMN Ord_ID INT NOT NULL 


ALTER TABLE [dbo].[orders_dimen] 
ALTER COLUMN Order_Date DATE  NULL 


ALTER TABLE [dbo].[orders_dimen] 
ADD PRIMARY KEY (Ord_ID )


-- Edits for the prod_dimen table


Select *
from [dbo].[prod_dimen]



UPDATE [dbo].[prod_dimen] SET  Prod_ID = TRIM('Prod_' FROM Prod_ID)

ALTER TABLE [dbo].[prod_dimen]
ALTER COLUMN Prod_ID INT NOT NULL 

ALTER TABLE [dbo].[prod_dimen]
ADD PRIMARY KEY (Prod_ID)


-- Edits for the shipping_dimen table


Select *
from [dbo].[shipping_dimen]


UPDATE [dbo].[shipping_dimen] SET  Ship_ID = TRIM('Ship_' FROM Ship_ID)

ALTER TABLE [dbo].[shipping_dimen]
ALTER COLUMN Ship_ID INT NOT NULL 

ALTER TABLE [dbo].[shipping_dimen]
ADD PRIMARY KEY (Ship_ID)


ALTER TABLE [dbo].[shipping_dimen]
ALTER COLUMN Ship_Date DATE  NULL 






















