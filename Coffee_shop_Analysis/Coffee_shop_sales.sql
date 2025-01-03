CREATE DATABASE Coffee_shop_sales;
USE Coffee_shop_sales;

SELECT * FROM coffee_sales;
DESC coffee_sales;

# Cleaning Data
UPDATE coffee_sales
SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_date DATE;

UPDATE coffee_sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_time TIME;

ALTER TABLE coffee_sales
CHANGE COLUMN `ï»¿transaction_id` transaction_id INT;

# Fetching KPI's Requirement

-- Total sales for each month
DELIMITER //
CREATE PROCEDURE Sales_by_month (IN X INT)
BEGIN
	 SELECT CONCAT(ROUND(SUM(unit_price * transaction_qty))," K") as Total_Sales 
FROM coffee_sales 
WHERE MONTH(transaction_date) = X;
END //

CALL Sales_by_month (3); -- Give month's no. as input

    --------------------------------------------------------------------------------------------------

# TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH

SELECT  
    MONTH(transaction_date) AS month,
    CONCAT(ROUND(SUM(unit_price * transaction_qty))," K") AS total_sales,
    CONCAT(ROUND(
        (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date))) 
        / LAG(SUM(unit_price * transaction_qty), 1) 
        OVER (ORDER BY MONTH(transaction_date)) * 100, 2), '%') AS mom_increase_percentage
FROM 
    coffee_sales
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
    --------------------------------------------------------------------------------------------------

-- Total Orders for each month
DELIMITER //
CREATE PROCEDURE Orders_by_month (IN X INT)
BEGIN
	 SELECT COUNT(*) as Total_Orders 
FROM coffee_sales 
WHERE MONTH(transaction_date) = X;
END //

CALL Orders_by_month (4); -- Give month's no. as input

   --------------------------------------------------------------------------------------------------

# TOTAL ORDERS KPI - MOM DIFFERENCE AND MOM GROWTH

SELECT  
    MONTH(transaction_date) AS month,
    COUNT(*) as Total_Orders,
    CONCAT(ROUND((COUNT(*) - LAG(COUNT(*), 1)
        OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(*), 1) 
        OVER (ORDER BY MONTH(transaction_date)) * 100, 2),"%") AS mom_increase_percentage
FROM 
    coffee_sales
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);

    --------------------------------------------------------------------------------------------------

-- Total Quantity sold for each month
DELIMITER //
CREATE PROCEDURE Total_QtySold_by_month (IN X INT)
BEGIN
	 SELECT SUM(transaction_qty) AS Total_quantity_sold 
FROM coffee_sales 
WHERE MONTH(transaction_date) = X;
END //

CALL Total_QtySold_by_month (4); -- Give month's no. as input

--------------------------------------------------------------------------------------------------

# TOTAL QUANTITY SOLD KPI - MOM DIFFERENCE AND MOM GROWTH

SELECT  
    MONTH(transaction_date) AS month,
    SUM(transaction_qty) AS Total_quantity_sold,
    CONCAT(ROUND((SUM(transaction_qty) - LAG(SUM(transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
        OVER (ORDER BY MONTH(transaction_date)) * 100, 2),"%") AS mom_increase_percentage
FROM 
    coffee_sales
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
-------------------------------------------------------------------------------------------------- 
    
-- CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS
    
SELECT
	transaction_date AS Calender,
    CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1)," K") AS total_sales,
    CONCAT(ROUND(SUM(transaction_qty)/1000,1)," K") AS total_quantity_sold,
    CONCAT(ROUND(COUNT(transaction_id)/1000,1)," K") AS total_orders
FROM 
    coffee_sales
GROUP BY Calender
ORDER BY Calender;

-- WEEKDAYS/WEEKENDS - TOTAL SALES

SELECT 
	 CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN "Weekends"
		  ELSE "Weekdays"
	 END AS Day_Type,
CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1)," K") AS total_sales
FROM coffee_sales
GROUP BY Day_Type;

-------------------------------------------------------------------------------------------------- 
    
-- TOTAL SALES BY STORE LOCATION

SELECT store_location,
	  CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1)," K") AS total_sales
FROM coffee_sales
GROUP BY store_location;

-------------------------------------------------------------------------------------------------- 

-- SALES TREND OVER PERIOD

SELECT CONCAT(ROUND(AVG(total_sales)/1000,1)," K") AS average_sales
FROM (
    SELECT 
        SUM(unit_price * transaction_qty) AS total_sales
    FROM 
        coffee_sales
	WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS inner_query;

-------------------------------------------------------------------------------------------------- 

-- DAILY SALES FOR MONTH SELECTED

SELECT 
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty),1) AS total_sales
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) = 5  -- Filter for May
GROUP BY 
   day_of_month
ORDER BY 
    day_of_month;

-------------------------------------------------------------------------------------------------- 

-- COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”

SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        ROUND(SUM(unit_price * transaction_qty),2) AS total_sales,
        ROUND(AVG(SUM(unit_price * transaction_qty)) OVER () ,2) AS avg_sales
    FROM 
        coffee_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;

-----------------------------------------------------------------------------------------
-- SALES BY PRODUCT CATEGORY
SELECT 
	product_category,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
GROUP BY product_category
ORDER BY Total_Sales DESC;

-----------------------------------------------------------------------------------------
-- SALES BY PRODUCTS (TOP 10)
SELECT 
	product_type,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales 
GROUP BY product_type
ORDER BY Total_Sales DESC
LIMIT 10;

-----------------------------------------------------------------------------------------
-- TotalSALES,Total_qty_sold,TotalOrders BY DAYS/HOURS

SELECT MONTHNAME(transaction_date) AS Month, 
CASE WHEN DAYOFWEEK(transaction_date) = 1 THEN "Sunday"
	 WHEN DAYOFWEEK(transaction_date) = 2 THEN "Monday"
     WHEN DAYOFWEEK(transaction_date) = 3 THEN "Tuesday"
     WHEN DAYOFWEEK(transaction_date) = 4 THEN "Wednesday"
     WHEN DAYOFWEEK(transaction_date) = 5 THEN "Thursday"
     WHEN DAYOFWEEK(transaction_date) = 6 THEN "Friday"
     WHEN DAYOFWEEK(transaction_date) = 7 THEN "Saturday"
END AS Day,
HOUR(transaction_time) AS HOUR,
ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
SUM(transaction_qty) AS Total_Quantity_sold,
COUNT(*) AS Total_Orders
FROM coffee_sales
GROUP BY Month,Day,HOUR;