CREATE DATABASE Swiggydb;

USE Swiggydb;

SELECT * FROM Swiggy_Data


-- checking null values

SELECT 
SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,
SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order,
SUM(CASE WHEN restaurant_name IS NULL THEN 1 ELSE 0 END) AS null_RName,
SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS null_location,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
SUM(CASE WHEN dish_name IS NULL THEN 1 ELSE 0 END) AS null_dish,
SUM(CASE WHEN price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
SUM(CASE WHEN rating_count IS NULL THEN 1 ELSE 0 END) AS null_count
FROM Swiggy_Data;

-- checking empty strings or cell
SELECT * FROM Swiggy_Data
WHERE 
State = '' OR City = '' OR Order_Date = '' OR Restaurant_Name = '' OR Location = '' OR Category = '' OR 
Dish_name = '' OR Price_INR = '' OR Rating = '' OR Rating_Count = '' ;

-- Duplicate value 
SELECT 
State,city,order_date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count,COUNT(*) AS Counting
FROM Swiggy_Data
GROUP BY State,city,order_date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count
HAVING COUNT(*) > 1;

-- Remove Duplicate 
WITH  CTE AS (
SELECT 
State,city,order_date,restaurant_name,location,category,dish_name,price_INR,Rating,rating_count,
ROW_NUMBER() OVER (PARTITION BY State,city,order_date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count 
ORDER BY (SELECT NULL) ) AS RowNum
FROM Swiggy_data)
DELETE FROM CTE
WHERE RowNum > 1;

--- data transformation
-- Creating table 
CREATE TABLE date_table(
date_id INT IDENTITY (1,1) PRIMARY KEY,
date_name DATE , 
year INT,
month INT,
month_name VARCHAR(50),
quarter INT,
day INT,
week INT)


CREATE TABLE location_table(
location_id INT IDENTITY (1,1) PRIMARY KEY,
state VARCHAR(50),
city VARCHAR(50),
location VARCHAR(200),
)

CREATE TABLE restaurant_table(
restaurant_id INT IDENTITY (1,1) PRIMARY KEY,
restaurant_name VARCHAR(200))

CREATE TABLE category_table(
category_id INT IDENTITY (1,1) PRIMARY KEY,
category VARCHAR(200))

CREATE TABLE dish_table(
dish_id INT IDENTITY (1,1) PRIMARY KEY,
dish_name VARCHAR(200))

CREATE TABLE Swiggy_orders(
Order_id INT IDENTITY(1,1) PRIMARY KEY,
Date_id INT,
Price_INR DECIMAL(10,2),
Rating DECIMAL(4,2),
Rating_count INT,
Location_id INT,
Restaurant_id INT,
Category_id INT,
Dish_id INT,
FOREIGN KEY (date_id) REFERENCES date_table(date_id),
FOREIGN KEY (location_id) REFERENCES location_table(location_id),
FOREIGN KEY (restaurant_id) REFERENCES Restaurant_table (restaurant_id),
FOREIGN KEY (Category_id) REFERENCES category_table(category_id),
FOREIGN KEY (Dish_id) REFERENCES dish_table(dish_id)
)


--- INSERTING VALUES

INSERT INTO date_table(date_name,year,month,month_name,quarter,day,week)
SELECT DISTINCT
Order_date,
YEAR(order_date),
MONTH(order_date),
DATENAME(MONTH,order_date),
DATEPART(QUARTER, order_date),
DAY(order_date),
DATEPART(WEEK,order_date)
FROM swiggy_data
WHERE order_date IS NOT NULL;

SELECT*FROM location_table;

INSERT INTO location_table( state,city,location)
SELECT DISTINCT 
State,
city,
location
FROM Swiggy_Data;

INSERT INTO restaurant_table(restaurant_name)
SELECT DISTINCT 
restaurant_name
FROM Swiggy_Data;

INSERT INTO category_table(category)
SELECT DISTINCT
category
FROM Swiggy_Data;

-- 
INSERT INTO dish_table(dish_name)
SELECT DISTINCT
dish_name 
FROM Swiggy_Data;

-- insert into swiggy_orders

INSERT INTO Swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM Swiggy_Data s

JOIN Date_table dd
    ON dd.date_name = s.Order_Date

JOIN location_table dl
    ON dl.State = s.State
    AND dl.City = s.City
    AND dl.location = s.location

JOIN restaurant_table dr
    ON dr.restaurant_name = s.restaurant_name

JOIN Category_table dc
    ON dc.category = s.category

JOIN Dish_table dsh
    ON dsh.Dish_name = s.Dish_Name

    SELECT * FROM Swiggy_Orders f

    JOIN date_table d ON f.date_id = d.date_id
    JOIN location_table l ON f.location_id = l.location_id
    JOIN restaurant_table r ON f.restaurant_id = r.restaurant_id
    JOIN category_table c ON f.category_id = c.category_id
    JOIN dish_table di ON f.dish_id  = di.dish_id;

SELECT* FROM swiggy_orders;


-- KPI'S 
--1.Total order 
SELECT COUNT(*) AS Total_order 
FROM Swiggy_orders; 

--SELECT COUNT(*) AS Total_order 
--FROM Swiggy_Data;

--2.Total Revenue
SELECT FORMAT(SUM(CONVERT(FLOAT, price_INR))/1000000,'N2') + 'M Million'
AS total_revenue
FROM Swiggy_orders

--3.AVG dish price
SELECT FORMAT(AVG(price_INR),'N2') 
AS Avg_dish_price
FROM Swiggy_orders;

--4.Avg rating
SELECT FORMAT(AVG(Rating),'N2') 
AS Avg_dish_price
FROM Swiggy_orders;

-- Which restaurants have the highest ratings in each city?
 WITH X AS (
        SELECT l.state,
        l.city, r.restaurant_name,
        FORMAT(AVG(f.rating),'N2') AS avge_rating,
        DENSE_RANK() OVER (PARTITION BY l.city ORDER BY AVG(f.rating) DESC) AS highest_ranking 
        FROM 
        Swiggy_orders f 
            JOIN location_table l
                ON l.location_id=f.Location_id
            JOIN restaurant_table r
                ON r.restaurant_id=f.Restaurant_id
        GROUP BY l.state,
             l.city, r.restaurant_name)
       SELECT * FROM X 
           WHERE highest_ranking = 1
        ORDER BY 
            avge_rating DESC

--.Restaurant in city with highest rating count and with average rating 
SELECT 
r.restaurant_name,l.city, 
SUM(rating_count) AS Number_of_ratings,
FORMAT(AVG(rating),'N2') AS Avg_rating
FROM Swiggy_orders f
    JOIN restaurant_table r
       ON R.restaurant_id=F.Restaurant_id
    JOIN location_table l
        ON l.location_id = f.Location_id
GROUP BY 
   l.city, r.restaurant_name
HAVING 
    SUM(rating_count) >= 100 AND AVG(rating) >= 3.90
ORDER BY 
     SUM(rating_count) DESC , AVG(rating) ASC

--How many numbers of orders placed and revenue generated over the period of time?
SELECT 
d.month,
d.month_name,
COUNT(DISTINCT Order_id) AS Total_orders,
FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000, 'N2')+ 'M' AS Total_revenue
FROM Swiggy_orders f
JOIN date_table d
ON f.date_id = d.date_id
GROUP BY
d.year,
d.month,
d.month_name
ORDER BY COUNT(DISTINCT Order_id) DESC;

--.Top 10 cities with number of order placed
SELECT --TOP 10 
l.city,COUNT(*) AS Top_orders
FROM Swiggy_orders f
JOIN location_table l
ON l.location_id = f.location_id
GROUP BY 
l.city
ORDER BY SUM(Price_INR) DESC;

--.Find the Number of orders placed on each day of a week 

SELECT 
DATENAME(WEEKDAY, d.date_name) AS day, COUNT(*) AS order_frequency
FROM Swiggy_orders f
JOIN date_table d
ON f.date_id = d.date_id
GROUP BY 
DATENAME(WEEKDAY,d.date_name)
ORDER BY COUNT(*) DESC

--.What is the revenue contibution and total number of order placed by each state?
--  returened state name, number of orders, total revenue, percentage contribution 
SELECT 
        l.state, 
         COUNT(*) AS Total_orders,
          CONVERT(DECIMAL(10,2),SUM( price_INR))  AS Revenue,
        FORMAT( SUM(CONVERT(DECIMAL(10,2),price_INR))*100/
                            (SELECT SUM(price_INR) FROM Swiggy_orders),'N2') AS percentage_contribution
FROM swiggy_orders f
        JOIN location_table l
            ON l.location_id = f.Location_id
GROUP BY l.state
ORDER BY SUM(CONVERT(FLOAT, price_INR))  DESC

--.What are top 3 restaurants with highest revenue in each state
WITH rest_revenue AS (
SELECT
    l.state,
    r.restaurant_name, 
    FORMAT(SUM(CONVERT(FLOAT, price_INR))/1000000, 'N2') + 'M' AS Restaurants_Revenue,
    DENSE_RANK() OVER (PARTITION BY l.state ORDER BY SUM(CONVERT(FLOAT, price_INR)) DESC) AS ranked 
FROM Swiggy_orders f
         JOIN restaurant_table r 
             ON r.restaurant_id = f.Restaurant_id
         JOIN location_table l
             ON l.location_id=f.Location_id
GROUP by 
   l.state, r.restaurant_name
 )
SELECT * FROM rest_revenue 
WHERE ranked <= 3
ORDER BY 
    state,
   Restaurants_Revenue DESC;

--Which restaurants offer the widest variety of dishes?
SELECT 

r.restaurant_name,
COUNT(DISTINCT f.dish_id) AS Variety_dishes
FROM Swiggy_orders f
    JOIN restaurant_table r 
        ON r.restaurant_id = f.Restaurant_id
GROUP BY 
    r.restaurant_name
ORDER BY 
    Variety_dishes DESC

--Find the number of restaurants in each state and city.
SELECT l.state,l.city,
COUNT(DISTINCT r.restaurant_id) AS Reastaurant_in_area
FROM Swiggy_orders f
    JOIN restaurant_table r
        ON r.restaurant_id=f.Restaurant_id
    JOIN location_table l
        ON l.location_id=f.Location_id 
GROUP BY 
    l.state,l.city
ORDER BY
     Reastaurant_in_area DESC;

--Compare average ratings and rating counts across Segment dishes into affordable, mid-range, and premium price bands..

WITH Price_segment AS (
SELECT Dish_name, Rating,rating_count,
	CASE 
		WHEN price_inr >899 THEN 'Premium' 
		WHEN price_inr BETWEEN 499 AND 899 THEN 'Mid-range'
		ELSE  'Affordable'
		END
		AS Segments 
FROM Swiggy_Data),
--SELECT * FROM Price_segment
Bands_ratings AS ( 
SELECT 
    Segments, 
    ROUND(AVG(Rating),02) AS avg_rating,
    SUM(rating_count) AS Total_ratings
    FROM Price_segment
GROUP BY 
    Segments
)
    SELECT *  FROM Bands_ratings
    ORDER BY 
        avg_rating DESC


--18.Month sales growth : sales growth rate
WITH Monthsales AS (
    
    SELECT 
            YEAR(order_date) AS year,
            MONTH(order_date) AS Monthnum,
            DATENAME(MONTH,order_date) AS Months,
            CONVERT(DECIMAL(10,2),SUM(price_inr)) AS cr_month_sales 
   FROM swiggy_data 
        GROUP BY 
            YEAR(order_date) ,
            MONTH(order_date) ,
            DATENAME(MONTH,order_date)
        ),
   -- SELECT * FROM Monthsales
salesgrowth AS (
    SELECT 
        year,
        months,
        monthnum,
        cr_month_sales,
        LAG(cr_month_sales,1) OVER ( ORDER BY year , monthnum) AS pre_month_sales 
    FROM Monthsales
    )
    SELECT year,
        months,
        monthnum,
        cr_month_sales,
      CONVERT(DECIMAL(10,2),(cr_month_sales - pre_month_sales)*100.0
        / NULLIF(pre_month_sales , 0)) AS percentage_growth
                
        FROM salesgrowth;







       



