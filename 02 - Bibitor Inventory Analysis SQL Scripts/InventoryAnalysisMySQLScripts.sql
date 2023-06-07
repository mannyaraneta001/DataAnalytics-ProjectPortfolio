/* Inventory Analysis for Bibitor LLC: MySQL Scripts

The purpose of this project is to analyze three areas of interest in Bibitor's inventory data, namely:
(1) Supplier Relations
(2) Store Performance
(3) Profitability

*/

CREATE SCHEMA bibitor;

#Data PreProcessing

-- Importing PricingPurchases Dataset

CREATE TABLE pricingpurchasesdec (
	Brand FLOAT, 
    Description VARCHAR(255),
    Price FLOAT,
    Size VARCHAR(50),
    Volume VARCHAR(50),
    Classification FLOAT,
    PurchasePrice FLOAT,
    VendorNumber FLOAT,
    VendorName VARCHAR(255)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2017PurchasePricesDec.csv' INTO TABLE pricingpurchasesdec
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DESCRIBE pricingpurchasesdec;

-- Importing BegInv Dataset

CREATE TABLE BegInvDec (
	InventoryId TEXT, 
	Store INT,
    City TEXT,
    Brand INT,
    Description TEXT,
    Size TEXT,
    onHand INT,
    Price DOUBLE,
    startDate TEXT
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\BegInvFINAL12312016.csv' INTO TABLE BegInvDec
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- Importing EndInv Dataset

CREATE TABLE EndInvDec (
	InventoryId TEXT, 
	Store INT,
    City TEXT,
    Brand INT,
    Description TEXT,
    Size TEXT,
    onHand INT,
    Price DOUBLE,
    endDate TEXT
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\EndInvFINAL12312016.csv' INTO TABLE EndInvDec
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- Invoice Purchases - small file (578 kb) , loaded via import wizard

-- Importing Purchases Dataset

CREATE TABLE PurchasesDec (
	InventoryId TEXT,
    Store INT,
    Brand INT,
    Description TEXT,
    Size TEXT,
    VendorNumber INT,
    VendorName TEXT,
    PONumber INT,
    PODate TEXT,
    ReceivingDate TEXT,
    InvoiceDate TEXT,
    PayDate TEXT,
    PurchasePrice DOUBLE,
    Quantity INT,
    Dollars DOUBLE, 
    Classification INT
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\PurchasesFINAL12312016.csv' INTO TABLE PurchasesDec
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- Importing Sales Dataset

CREATE TABLE SalesDec (
	InventoryId TEXT,
    Store INT, 
    Brand INT,
    Description TEXT,
    Size TEXT,
    SalesQuantity INT, 
    SalesDollars DOUBLE,
    SalesPrice DOUBLE,
    SalesDate TEXT,
    Volume INT,
    Classification INT,
    ExciseTax DOUBLE,
    VendorNo INT,
    VendorName TEXT
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\SalesFINAL12312016.csv' INTO TABLE SalesDec
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; 

SELECT FORMAT(COUNT(*),0) FROM salesdec;

DROP TABLE salesdec;

-- All datasets have been loaded. Total Obs = 15,645,659

## Assessing SUPPLIER RELATIONS Through Vendor Billings and Purchase Activity

-- Preliminary Inspection

SELECT * FROM beginvdec;
SELECT FORMAT(COUNT(*),0) AS count
FROM (
		SELECT DISTINCT brand FROM salesdec ) AS unique_cities;
SELECT * FROM endinvdec;
SELECT * FROM pricingpurchasesdec;
SELECT * FROM purchasesdec;

SELECT VendorName, Price
FROM pricingpurchasesdec
WHERE Brand = '8412'; -- PO 8124

SELECT * FROM vendorinvoicesdec;

SELECT COUNT(VendorNumber) 
FROM vendorinvoicesdec
WHERE VendorNumber = '105';

SELECT * FROM vendorinvoicesdec WHERE PONumber = '13607';

SELECT * FROM purchasesdec WHERE PONumber = '13607'; 

SELECT COUNT(VendorNumber)
FROM purchasesdec
WHERE VendorNumber = '105';

SELECT * FROM purchasesdec;

-- Aggregate Table for Vendor Billings 

-- Def: CriticalVendors are vendors whose dollar billings > $1000
-- Columns: VendorNumber, VendorName, QuantityPurchased, DollarValue

CREATE TABLE criticalvendors (
	VendorNumber INT,
    VendorName TEXT,
    TotalQty INT,
    DollarVal DOUBLE
);

INSERT INTO criticalvendors (VendorNumber, VendorName, TotalQty, DollarVal)
SELECT
	VendorNumber, 
    VendorName,
    SUM(Quantity) AS TotalQty,
    SUM(Dollars) AS DollarVal
FROM purchasesdec
GROUP BY VendorNumber, VendorName
HAVING SUM(Dollars) > 1000;

SELECT * FROM criticalvendors;

-- Viewing Table for readability
SELECT 
	VendorNumber, 
    VendorName,
    FORMAT(TotalQty, 0) AS fmt_TotalQty, 
    FORMAT(DollarVal, 2) AS fmt_DollarVal
FROM 
	criticalvendors;

-- Extracting Top 10 and Bottom 10 Vendors by Quantity

CREATE TABLE Top10ByQty AS
SELECT * 
FROM criticalvendors
ORDER BY TotalQty DESC
LIMIT 10; 

SELECT 
	VendorNumber, 
    VendorName,
    FORMAT(TotalQty, 0) AS fmt_TotalQty, 
    FORMAT(DollarVal, 2) AS fmt_DollarVal
FROM 
	top10byqty;

CREATE TABLE Bot10ByQty AS
SELECT *
FROM criticalvendors
ORDER BY TotalQty ASC
LIMIT 10; 

SELECT 
	VendorNumber, 
    VendorName,
    FORMAT(TotalQty, 0) AS fmt_TotalQty, 
    FORMAT(DollarVal, 2) AS fmt_DollarVal
FROM 
	bot10byqty;

-- Extracting Top 10 and Bottom 10 Vendors by DollarValue

CREATE TABLE Top10ByVal
SELECT * 
FROM criticalvendors
ORDER BY DollarVal DESC
LIMIT 10;

SELECT 
	VendorNumber, 
    VendorName,
    FORMAT(TotalQty, 0) AS fmt_TotalQty, 
    FORMAT(DollarVal, 2) AS fmt_DollarVal
FROM 
	top10byval;
    
CREATE TABLE Bot10ByVal
SELECT * 
FROM criticalvendors
ORDER BY DollarVal ASC
LIMIT 10;

SELECT 
	VendorNumber, 
    VendorName,
    FORMAT(TotalQty, 0) AS fmt_TotalQty, 
    FORMAT(DollarVal, 2) AS fmt_DollarVal
FROM 
	bot10byval;

-- Aggregate Table for Purchase Activity
-- Columns: VendorNumber, VendorName, PO_Receive, Invoice_Payment, Quantity
SELECT * FROM purchasesdec;

CREATE TABLE purchaseactivity (
	VendorNumber INT, 
    VendorName TEXT,
    PO_Receive TEXT, 
    Invoice_Payment TEXT,
    Quantity INT
);

INSERT INTO purchaseactivity (VendorNumber, VendorName, PO_Receive, Invoice_Payment, Quantity)
SELECT
	VendorNumber, 
    VendorName,
    DATEDIFF(ReceivingDate, PODate) AS PO_Receive, 
    DATEDIFF(PayDate, InvoiceDate) AS Invoice_Payment,
    Quantity
FROM purchasesdec;

SELECT * FROM purchaseactivity;

-- Area of Interest: How many days it takes vendors to deliver items from issuance of Purcahse order to Delivery? 
-- For this analysis, PO_Receive and Invoice_Payment columns are converted to FLOAT

ALTER TABLE purchaseactivity
MODIFY COLUMN PO_Receive FLOAT,
MODIFY COLUMN Invoice_Payment FLOAT;

DESCRIBE purchaseactivity;

-- Subsequently, the relevant entries associated to each vendor is averaged to determine supplier performance 

CREATE TABLE avg_purchaseact (
	VendorNumber INT,
    VendorName TEXT,
    avg_PO_Receipt FLOAT,
    avg_Inv_Pay FLOAT
);

SELECT * FROM purchaseactivity;

INSERT INTO avg_purchaseact (VendorName, VendorNumber, avg_PO_Receipt, avg_Inv_Pay)
SELECT 
	VendorName, 
    VendorNumber, 
    AVG(PO_Receive) AS avg_PO_Receipt,
    AVG(Invoice_Payment) AS avg_Inv_Pay
FROM purchaseactivity
GROUP BY VendorName, VendorNumber; 

SELECT * FROM avg_purchaseact; 

## Assessing STORE PERFORMANCE through inventory management, purchase activity, and store sales

-- Inv Management: How many days does it take each store, on average, to pay from receipt of purchase invoice from vendor? 

CREATE TEMPORARY TABLE invoice2payment
SELECT 
	Store,
    InvoiceDate,
    PayDate,
    DATEDIFF(PayDate,InvoiceDate) AS DaysFromInvoice2Payment
FROM
	purchasesdec;

CREATE TABLE days_inv2payment
SELECT
	Store, 
    AVG(DaysFromInvoice2Payment) AS inv2payment
FROM 
	invoice2payment
GROUP BY
	Store;

SELECT * FROM days_inv2payment;

-- ISSUE: Stores are numeric assignments. For better presentation, consider the cities in which each store is located

SELECT city, COUNT(DISTINCT Store) AS Store_Count
FROM endinvdec
GROUP BY city
HAVING COUNT(DISTINCT Store) > 1;

CREATE TABLE city_store_index
SELECT DISTINCT Store, City
FROM endinvdec;

SELECT * FROM city_store_index;

-- Update days_inv2payment table 
ALTER TABLE days_inv2payment
ADD COLUMN City TEXT AFTER Store;

UPDATE days_inv2payment a 
JOIN city_store_index b ON a.Store = b.Store
SET a.City = b.City;

SELECT * FROM days_inv2payment;

-- Extracting Top 10 Stores (Prompt)

CREATE TABLE two_top10_inv2payment
SELECT * 
FROM 
	days_inv2payment
ORDER BY
	inv2payment ASC
LIMIT
	10;

SELECT * FROM two_top10_inv2payment;

-- Extracting Bottom 10 (Not so prompt) Stores

CREATE TABLE two_bot10_inv2payment
SELECT * 
FROM 
	days_inv2payment
ORDER BY 
	inv2payment DESC
LIMIT
	10;

SELECT * FROM two_bot10_inv2payment;

-- PurchaseActivity: Store Performance in terms of Purchase Order Quantity

CREATE TABLE storeorders
SELECT
	Store,
    SUM(Quantity) AS OrderQTY,
    SUM(Dollars) AS TotalPayable
FROM 
	purchasesdec 
GROUP BY
	Store;

ALTER TABLE storeorders
ADD COLUMN City TEXT AFTER Store;

UPDATE storeorders a
JOIN city_store_index b ON a.Store = b.Store
SET a.City = b.City;

SELECT * FROM storeorders; 

-- Extract Top 10 By Order QTY

CREATE TABLE two_topqty
SELECT * 
FROM
	storeorders
ORDER BY
	OrderQty DESC
LIMIT 
	10;

SELECT 
	Store,
	City,
    FORMAT(OrderQTY,0) AS OrderQTY,
    FORMAT(TotalPayable,2) AS TotalPayable
FROM 
	two_topqty;

-- Extract Bottom 10 by Order Qty
CREATE TABLE two_botqty
SELECT * 
FROM
	storeorders
ORDER BY
	OrderQTY ASC
LIMIT
	10;
    
SELECT 
	Store,
	City,
    FORMAT(OrderQTY,0) AS OrderQTY,
    FORMAT(TotalPayable,2) AS TotalPayable
FROM
	two_botqty;
-- Observation: OrderQTY and TotalPayable may be analyzed for linear regression to see how the two are related. 

-- Extract Top 10 by TotalPayable
CREATE TABLE two_toppay
SELECT * 
FROM
	storeorders
ORDER BY
	TotalPayable DESC
LIMIT 
	10;

SELECT 
	Store,
	City,
    FORMAT(OrderQTY,0) AS OrderQTY,
    FORMAT(TotalPayable,2) AS TotalPayable
FROM
	two_toppay;

-- Extract Bottom 10 by TotalPayable

CREATE TABLE two_botpay
SELECT * 
FROM
	storeorders
ORDER BY
	TotalPayable ASC
LIMIT
	10;
    
SELECT 
	Store,
	City,
    FORMAT(OrderQTY,0) AS OrderQTY,
    FORMAT(TotalPayable,2) AS TotalPayable
FROM
	two_botpay;

-- PurchaseActivity: Store Performance in terms of Sales and Quantity

CREATE TABLE storesales
SELECT
	Store,
    SUM(SalesQuantity) AS SaleQty,
    SUM(SalesDollars) AS TotalSales
FROM
	salesdec
GROUP BY
	Store;

ALTER TABLE storesales
ADD COLUMN City TEXT AFTER Store;

UPDATE storesales a 
JOIN city_store_index b ON a.Store = b.Store
SET a.City = b.City;

-- Extract Top 10 Stores by TotalSales

CREATE TABLE two_topsales
SELECT * 
FROM 
	storesales
ORDER BY
	TotalSales DESC
LIMIT
	10;

SELECT
	Store,
    City,
    FORMAT(SaleQty,0) AS SalesQty,
    FORMAT(TotalSales,2) AS TotaSales
FROM
	two_topsales;

-- Extract Bottom 10 Stores by TotalSales
CREATE TABLE two_botsales
SELECT * 
FROM
	storesales
ORDER BY
	TotalSales ASC
LIMIT
	10;

SELECT
	Store,
    City,
    FORMAT(SaleQty,0) AS SalesQty,
    FORMAT(TotalSales,2) AS TotaSales
FROM
	two_botsales;

-- Extract Top 10 Stores by SalesQty
CREATE TABLE two_topsalesqty
SELECT * 
FROM 
	storesales
ORDER BY
	SaleQty DESC
LIMIT
	10;

SELECT
	Store,
    City,
    FORMAT(SaleQty,0) AS SalesQty,
    FORMAT(TotalSales,2) AS TotaSales
FROM
	two_topsalesqty;
    
-- Extract Bottom 10 Stores by SalesQty
CREATE TABLE two_botsalesqty
SELECT * 
FROM
	storesales
ORDER BY
	SaleQty ASC
LIMIT 
	10;

SELECT
	Store,
    City,
    FORMAT(SaleQty,0) AS SalesQty,
    FORMAT(TotalSales,2) AS TotaSales
FROM
	two_botsalesqty;
    
## PROFITABILITY ANALYSIS

-- PreProcessing and Inspections
SELECT * FROM profitabilitydata;

SELECT * FROM filtered_profitability;

CREATE TEMPORARY TABLE brand_purchase
SELECT DISTINCT
	Brand,
    Description,
    PurchasePrice
FROM 
	purchasesdec;
-- 10664 unique brands from purchasesdec

UPDATE filtered_profitability a
JOIN brand_purchase b ON a.Brand = b.Brand
SET a.PurchasePrice = b.PurchasePrice;

SELECT * FROM filtered_profitability;

SELECT * FROM filtered_profitability WHERE PurchasePrice = '0' OR PurchasePrice = NULL; -- 751 rows have '0' as purchase price

-- Examine rows with 0 purchase price and test if this can be sourced from another dataset (pricingpurchasesdec)
CREATE TEMPORARY TABLE zeroprices
SELECT * 
FROM 
	filtered_profitability
WHERE
	PurchasePrice = '0' OR PurchasePrice = NULL;

UPDATE zeroprices a
JOIN pricingpurchasesdec b ON a.Brand = b.Brand
SET a.PurchasePrice = b.PurchasePrice
WHERE a.PurchasePrice = 0;

SELECT * FROM zeroprices;

ALTER TABLE zeroprices
ADD COLUMN PriceDiff DOUBLE,
ADD COLUMN ProfitMargin DOUBLE;

UPDATE zeroprices
SET 
	PriceDiff = SalesPrice - PurchasePrice,
	ProfitMargin = (SalesPrice - PurchasePrice) / SalesPrice * 100;

select * from zeroprices where salesprice = '0';
select * from pricingpurchasesdec where brand = '25340'; -- salesprice is 24.99 for item w/ purchase price 17.23

UPDATE zeroprices
SET SalesPrice = 24.99
WHERE Brand = '25340';

SELECT MAX(ProfitMargin) FROM filtered_profitability;
SELECT * FROM zeroprices WHERE ProfitMargin = '53.02120848339336';

-- Apply Treatment to filtered_profitability dataset

SELECT * FROM filtered_profitability; -- 751 rows with 0 as PurchasePrice

UPDATE filtered_profitability a
JOIN pricingpurchasesdec b ON a.Brand = b.Brand
SET a.PurchasePrice = b.PurchasePrice
WHERE a.PurchasePrice = 0; -- 751 rows properly updated as in the zeroprices temp test

SELECT * FROM filtered_profitability WHERE SalesPrice = '0'; -- Brand: 3046, 19669, 25340, 19465, 3963 / (35.81,6.06,17.23,4.72,11.36)
SELECT * FROM pricingpurchasesdec WHERE Brand = '3963'; -- Price: 47.99, 11.99, 24.99, 6.99, 14.99 | PurchasePrices matched

UPDATE filtered_profitability
SET SalesPrice = 
	CASE
		WHEN Brand = 3046 THEN 47.99
        WHEN Brand = 19669 THEN 11.99
        WHEN Brand = 25340 THEN 24.99
        WHEN Brand = 19465 THEN 6.99
        WHEN Brand = 3963 THEN 14.99
        ELSE SalesPrice -- to retain existing value
	END
WHERE Brand IN (3046, 19669, 25340, 19465, 3963) ;

SELECT * FROM filtered_profitability WHERE SalesPrice = '0'; -- returned 0 rows, all affected rows have been treated accordingly
SELECT * FROM filtered_profitability WHERE PurchasePrice = '0'; -- returned 0 rows; final check to avoid divisibility errors

-- PriceDiff and ProfitMargin Columns may be added now

ALTER TABLE filtered_profitability
ADD COLUMN PriceDiff DOUBLE,
ADD COLUMN ProfitMargin DOUBLE;

SELECT * FROM filtered_profitability;

UPDATE filtered_profitability
SET 
	PriceDiff = SalesPrice - PurchasePrice,
    ProfitMargin = (SalesPrice - PurchasePrice) / SalesPrice * 100; 

SELECT * FROM filtered_profitability; -- fix columns for standard presentation

UPDATE filtered_profitability
SET
	PriceDiff = ROUND(PriceDiff, 2),
    ProfitMargin = ROUND(ProfitMargin, 2);

SELECT * FROM filtered_profitability; -- columns fixed properly

SELECT * FROM filtered_profitability WHERE ProfitMargin < 0; -- NOTE!! 191 brands sold at a loss, biggest is almost 12 pricediff 

-- Extract top 10 Brands in terms of profit margin
CREATE TABLE top_profit
SELECT * 
FROM
	filtered_profitability
ORDER BY
	ProfitMargin DESC 
LIMIT
	10;

SELECT * FROM top_profit;

-- Extract Bottom 10 Profit
CREATE TABLE bot_profit
SELECT * 
FROM
	filtered_profitability
ORDER BY
	ProfitMargin ASC 
LIMIT
	10;

SELECT * FROM bot_profit; -- shows negative margins

SELECT * FROM filtered_profitability WHERE ProfitMargin < 0; -- record of all brands w/ negative profit

-- Extract top 10 Brands in terms of price diff
CREATE TABLE top_price
SELECT * 
FROM
	filtered_profitability
ORDER BY 
	PriceDiff DESC 
LIMIT
	10;

SELECT
	Brand,
    Description,
    VendorNo,
    VendorName,
    FORMAT(SalesPrice, 2) AS SalesPrice,
    FORMAT(PurchasePrice, 2) AS PurchasePrice,
    FORMAT(PriceDiff, 2) AS PriceDiff,
    ProfitMargin
FROM
	top_price;

-- Extract Bottom 10 in terms of price diff
CREATE TABLE bot_price
SELECT * 
FROM
	filtered_profitability
ORDER BY
	PriceDiff ASC 
LIMIT 
	10;

SELECT
	Brand,
    Description,
    VendorNo,
    VendorName,
    FORMAT(SalesPrice, 2) AS SalesPrice,
    FORMAT(PurchasePrice, 2) AS PurchasePrice,
    FORMAT(PriceDiff, 2) AS PriceDiff,
    ProfitMargin
FROM
	bot_price;

-- Top 10 most profitable vendors in terms of pricediff 

CREATE TEMPORARY TABLE fortop_vendors
SELECT
	VendorNo,
    VendorName,
    AVG(PriceDiff) AS PriceDiff,
    AVG(ProfitMargin) AS ProfitMargin
FROM
	filtered_profitability
GROUP BY
	VendorNo,
    VendorName;

CREATE TABLE top_vendors
SELECT * 
FROM
	fortop_vendors
ORDER BY
	PriceDiff DESC 
LIMIT 
	10;

SELECT
	VendorNo,
    VendorName,
    FORMAT(PriceDiff,2) AS PriceDiff,
    FORMAT(ProfitMargin,2) AS ProfitMargin
FROM
	top_vendors;

-- Bottom 10 vendors in terms of price diff
CREATE TABLE bot_vendors
SELECT * 
FROM
	fortop_vendors
ORDER BY
	PriceDiff ASC
LIMIT 
	10;

SELECT
	VendorNo,
    VendorName,
    FORMAT(PriceDiff,2) AS PriceDiff,
    FORMAT(ProfitMargin,2) AS ProfitMargin
FROM
	bot_vendors;

-- Top 10 In demand brands

CREATE TABLE indemand_brands
SELECT
	Brand,
    Description,
    SalesQuantity
FROM
	salesdec
GROUP BY
	Brand,
    Description,
    SalesQuantity
ORDER BY
	SalesQuantity DESC 
LIMIT
	10;

SELECT * FROM indemand_brands;

-- Bottom 10 Brands in terms of demand
CREATE TABLE lowdemand_brands
SELECT
	Brand,
    Description,
    SalesQuantity
FROM
	salesdec
GROUP BY
	Brand,
    Description,
    SalesQuantity
ORDER BY
	SalesQuantity ASC
LIMIT
	10;

SELECT * FROM lowdemand_brands;

## To retrieve further data for visualization

SELECT -- total orders and payables per store
	Store, 
    SUM(OrderQTY) AS OrderQty,
    ROUND(SUM(TotalPayable),2) AS TotalPayable
FROM
	storeorders
GROUP BY
	Store;

SELECT * FROM storesales;

SELECT -- total sales qty and dollars per store
	Store,
    SUM(SaleQty) AS SalesQTY,
    ROUND(SUM(TotalSales),2) AS TotalSales
FROM
	storesales
GROUP BY
	Store;

SELECT -- avg purchase qty per customer and sales
	Store,
    ROUND(AVG(SalesQuantity),2) AS SalesQty,
    ROUND(AVG(SalesDollars),2) AS TotalSales
FROM
	salesdec
GROUP BY
	Store;

SELECT -- TotalSales per Month
	EXTRACT(YEAR_MONTH FROM SalesDate) AS Month,
    SUM(SalesQuantity) AS SalesQTY,
    ROUND(SUM(SalesDollars),2) AS TotalSales
FROM
	salesdec
GROUP BY
	Month 
ORDER BY
	Month;

SELECT -- TotalPurchases per Month
	EXTRACT(YEAR_MONTH FROM ReceivingDate) AS Month,
    SUM(Quantity) AS PurchaseQTY,
    ROUND(SUM(Dollars),2) AS TotalPurchases
FROM
	purchasesdec
GROUP BY
	Month 
ORDER BY
	Month;
	
										## END OF ANALYSIS: NOTHING FOLLOWS ##
