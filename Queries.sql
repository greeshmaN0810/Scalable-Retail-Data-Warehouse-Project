

-- Query 1: The dates have to be updated to after 2014.
Select * from DIMSTORE;

UPDATE DIMSTORE SET STOREOPENINGDATE= DATEADD(DAY, UNIFORM(0,3000,RANDOM()), '2014-01-01')
COMMIT;

--Query 2: Updating Store Table in such a way that the stores 91-100 are open in the last 12 months
SELECT * FROM DIMSTORE WHERE STOREID BETWEEN 91 AND 100;
UPDATE DIMSTORE SET STOREOPENINGDATE= DATEADD(DAY, UNIFORM(0,360,RANDOM()), '2023-07-30') 
WHERE STOREID BETWEEN 91 AND 100;
COMMIT;

--QUERY 3: Update the customer table so that any customer that is at least 12 years old
SELECT * FROM DIMCUSTOMER WHERE DATEOFBIRTH >=DATEADD(YEAR, -12,CURRENT_DATE);

UPDATE DIMCUSTOMER SET DATEOFBIRTH = DATEADD(YEAR,-12,DATEOFBIRTH) WHERE DATEOFBIRTH >= DATEADD(YEAR, -12,CURRENT_DATE);

--QUERY 4: Making sure the dates align with the fact order table

--first identify the records that have a problem 
-- identify a valid date that can be entered
-- then update

UPDATE FACTORDERS f
SET f.dateid = r.dateid
FROM (
    SELECT orderid, d.dateid 
    FROM (
        SELECT orderid, 
            DATEADD(DAY, 
                DATEDIFF(DAY, S.STOREOPENINGDATE, CURRENT_DATE) * UNIFORM(1,10, RANDOM()) * 0.1, 
                S.STOREOPENINGDATE
            ) AS new_Date
        FROM FACTORDERS F
        JOIN DIMDATE D ON F.DATEID = D.DATEID
        JOIN DIMSTORE S ON F.STOREID = S.STOREID
        WHERE D.DATE < S.STOREOPENINGDATE
    ) o
    JOIN DIMDATE d ON o.new_Date = d.date
) r
WHERE f.orderid = r.orderid;

COMMIT;

--QUERY 5: list customers who havent made any order in the last 30 days 

SELECT * 
FROM dimcustomer 
WHERE customerid NOT IN (
    SELECT DISTINCT c.Customerid 
    FROM dimcustomer c
    JOIN factorders f ON c.customerid = f.customerid
    JOIN dimdate d ON f.dateid = d.dateid
    WHERE d.date >= DATEADD(MONTH, -1, CURRENT_DATE)
);

--Query 6: List the store that opened most recently and the sale it has done since then
WITH store_rank AS (
    SELECT storeid, storeopeningdate, 
           ROW_NUMBER() OVER (ORDER BY storeopeningdate DESC) AS final_Rank 
    FROM DIMSTORE
),
most_recent_store AS (
    SELECT storeid 
    FROM store_rank 
    WHERE final_rank = 1
),
store_amount AS (
    SELECT o.storeid, SUM(totalamount) AS totalamount 
    FROM factorders o 
    JOIN most_recent_store s ON o.storeid = s.storeid 
    GROUP BY o.storeid
)
SELECT s.*, a.totalamount 
FROM dimstore s 
JOIN store_amount a ON s.storeid = a.storeid;

--Query 7:finding customers who have ordered products from more than 2 categories in the last 6 months
WITH BASE_DATA AS (
    SELECT O.CUSTOMERID, P.CATEGORY 
    FROM FACTORDERS O 
    JOIN DIMDATE D ON O.DATEID = D.DATEID
    JOIN DIMPRODUCT P ON O.PRODUCTID = P.PRODUCTID
    WHERE D.DATE >= DATEADD(MONTH, -6, CURRENT_DATE)
    GROUP BY O.CUSTOMERID, P.CATEGORY
)
SELECT CUSTOMERID
FROM BASE_DATA
GROUP BY CUSTOMERID
HAVING COUNT(DISTINCT CATEGORY) > 2;

--Query 8: Get the monthly total sales for the 2024 year 
SELECT MONTH, SUM(TOTALAMOUNT) AS MONTHLY_AMOUNT 
FROM FACTORDERS O 
JOIN DIMDATE D ON O.DATEID = D.DATEID
WHERE D.YEAR = 2024
GROUP BY MONTH
ORDER BY MONTH;

--Query 9: find the highest discount given on any order in the year 2024
WITH base_data AS (
    SELECT discountAMOUNT, 
           ROW_NUMBER() OVER (ORDER BY discountAMOUNT DESC) AS discountAMOUNT_rank 
    FROM FACTORDERS O 
    JOIN DIMDATE D ON O.DATEID = D.DATEID
    WHERE D.DATE >= DATEADD(YEAR, -1, CURRENT_DATE)
)
SELECT * 
FROM base_data 
WHERE discountAMOUNT_rank = 1;

-- Query 10: Calculating the total sales (unit price * quantity)
SELECT SUM(quantityordered * unitprice) 
FROM FACTORDERS O 
JOIN DIMPRODUCT P ON O.productid = P.productid;

--Query 11: Showing the customerid of customer who has taken max lifetime discount 
-- rank
SELECT customerid 
FROM factorders f
GROUP BY customerid
ORDER BY SUM(discountamount) DESC 
LIMIT 1;

--QUERY 12:list of customers who placed max number of orders till date
WITH base_data AS (
    SELECT customerid, COUNT(orderid) AS order_count 
    FROM factorders f
    GROUP BY customerid
),
order_Rank_data AS (
    SELECT b.*, 
           ROW_NUMBER() OVER (ORDER BY order_count DESC) AS order_rank 
    FROM base_data b
)
SELECT customerid, order_count 
FROM order_Rank_data 
WHERE order_rank = 1;

--Query 13:showing top 3 brands based on their sales in the last year
WITH brand_Sales AS (
    SELECT brand, SUM(totalamount) AS total_Sales 
    FROM FACTORDERS f 
    JOIN dimdate d ON f.dateid = d.dateid
    JOIN dimproduct p ON f.productid = p.productid
    WHERE d.date >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY brand
),
brand_sales_rank AS (
    SELECT s.*, 
           ROW_NUMBER() OVER (ORDER BY total_Sales DESC) AS sales_rank 
    FROM brand_Sales s
)
SELECT brand,total_sales
FROM brand_sales_rank 
WHERE sales_rank <= 3;

--Query 14: when discount and cost is fixed will the sum of total amount be less/more 
SELECT CASE 
    WHEN SUM(orderamount - orderamount * 0.05 - orderamount * 0.08) > SUM(totalamount) 
    THEN 'yes' 
    ELSE 'no' 
END 
FROM factorders f 
LIMIT 10;

--Query 15: Information of the customer and their current loyatly program status

SELECT l.programtier, COUNT(customerid) AS customer_count 
FROM dimcustomer d 
JOIN dimloyaltyprogram l ON d.loyaltyprogramid = l.loyaltyprogramid 
GROUP BY l.programtier;

-- Query 16: showing region category wise amount for the last 6 months
SELECT region, category, SUM(totalamount) AS total_sales
FROM FACTORDERS F
JOIN dimdate d ON f.dateid = d.dateid
JOIN dimproduct p ON f.productid = p.productid
JOIN dimstore s ON f.storeid = s.storeid
WHERE d.date >= DATEADD(MONTH, -6, CURRENT_DATE)
GROUP BY region, category;

--Query 17:showing the top 5 products based on quantity ordered in the last 3 years 
WITH QUANTITY_DATA AS (
    SELECT F.PRODUCTID, SUM(QUANTITYORDERED) AS TOTAL_Quantity 
    FROM FACTORDERS F 
    JOIN DIMDATE D ON F.DATEID = D.DATEID
    WHERE D.DATE >= DATEADD(YEAR, -3, CURRENT_DATE)
    GROUP BY F.PRODUCTID
),
quantity_rank_data AS (
    SELECT q.*, 
           ROW_NUMBER() OVER (ORDER BY TOTAL_Quantity DESC) AS quantity_Wise_rank 
    FROM QUANTITY_DATA q
)
SELECT productid, TOTAL_Quantity 
FROM quantity_rank_data 
WHERE quantity_Wise_rank <= 5;

--Query 18:Listing the total amount for each loyalty program tier since year 2023

SELECT p.programname, SUM(totalamount) AS total_sales 
FROM FACTORDERS f
JOIN dimdate d ON f.dateid = d.dateid
JOIN dimcustomer c ON f.customerid = c.customerid
JOIN dimloyaltyprogram p ON c.loyaltyprogramid = p.loyaltyprogramid
WHERE d.year >= 2023
GROUP BY p.programname;


--Query 19: revenue generated by each store manager in March 2024

SELECT s.managername, SUM(totalamount) AS total_sales 
FROM FACTORDERS f
JOIN dimdate d ON f.dateid = d.dateid
JOIN dimstore s ON f.storeid = s.storeid
WHERE d.year = 2024 AND d.month = 3
GROUP BY s.managername;

--Query 20:List of the avg order amount per store in the year 2024
SELECT s.storename, s.storetype, AVG(totalamount) AS total_sales 
FROM FACTORDERS f
JOIN dimdate d ON f.dateid = d.dateid
JOIN dimstore s ON f.storeid = s.storeid
WHERE d.year = 2024
GROUP BY s.storename, s.storetype;

--READING DATA FROM FILES 

--Query 21: Query data from customer csv that is present in the stage
SELECT $1, $2, $3
FROM 
@TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
(FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT');

-- Query 22: Aggregation in File
--Share the count of records in the Dim Customer File from stage
SELECT COUNT($1)
FROM 
@TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
(FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT');

--Query 23:Filter from files
-- Sharing the records from Dim Customer File where customer dob is greater than 1st jan 2000

SELECT $1, $2, $3, $4, $5, $6
FROM 
@TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
(FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
WHERE $4 > '2000-01-01';


--Query 24: Join Data from Multiple files 

-- Join DimCustomer and DimLoyalty and show the customer 1st name along with the program tier they are part of
WITH customer_data AS (
    SELECT $1 AS First_Name, $12 AS Loyalty_Program_ID
    FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
),
loyalty_data AS (
    SELECT $1 AS Loyalty_Program_ID, $3 AS program_tier
    FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimLoyaltyInfo/DimLoyaltyInfo.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
)
SELECT First_Name, program_tier 
FROM customer_data c 
JOIN loyalty_data l 
ON c.Loyalty_Program_ID = l.Loyalty_Program_ID;

-- Query 25 - GROUPBY
-- Join Dim Customer and Dim Loyalty, Show the Program Tier and the number of customers part of it.
-- Give the column name an alias "TotalCount"

WITH customer_data AS (
    SELECT $1 AS First_Name, $12 AS Loyalty_Program_ID
    FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
),
loyalty_data AS (
    SELECT $1 AS Loyalty_Program_ID, $3 AS program_tier
    FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimLoyaltyInfo/DimLoyaltyInfo.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
)
SELECT program_tier, COUNT(1) AS total_count
FROM customer_data c
JOIN loyalty_data l 
ON c.Loyalty_Program_ID = l.Loyalty_Program_ID
GROUP BY program_tier;

select * from dimcustomer

UPDATE dimcustomer d
SET PHONENUMBER = CONCAT(
        '+', t.COUNTRY_CODE, ' (', 
        SUBSTRING(t.LOCAL_NUMBER, 1, 3), ') ', 
        SUBSTRING(t.LOCAL_NUMBER, 4, 3), '-', 
        SUBSTRING(t.LOCAL_NUMBER, 7, 4)
    )
FROM (
    SELECT 
        EMAIL, 
        REGEXP_REPLACE(PHONENUMBER, '[^0-9]', '') AS CLEAN_PHONE,
        -- Extract a valid country code (1-3 digits) or default to '1'
        CASE 
            WHEN LENGTH(REGEXP_REPLACE(PHONENUMBER, '[^0-9]', '')) > 11 
                THEN LEFT(REGEXP_REPLACE(PHONENUMBER, '[^0-9]', ''), 3)  
            WHEN LENGTH(REGEXP_REPLACE(PHONENUMBER, '[^0-9]', '')) = 11 
                THEN LEFT(REGEXP_REPLACE(PHONENUMBER, '[^0-9]', ''), 1)  
            ELSE '1'  -- Default to +1 (US/Canada) if no country code
        END AS COUNTRY_CODE,
        -- Extract the last 10 digits as the local phone number
        RIGHT(REGEXP_REPLACE(PHONENUMBER, '[^0-9]', ''), 10) AS LOCAL_NUMBER
    FROM dimcustomer
) AS t
WHERE d.EMAIL = t.EMAIL;


commit;









    













