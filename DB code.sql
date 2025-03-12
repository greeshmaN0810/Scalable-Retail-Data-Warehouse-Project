-- create database
create database test_db;

--create schema 
create schema test_db_Schema;

-- Dimension Table: DimDate
CREATE TABLE DimDate (
    DateID INT PRIMARY KEY,
    Date DATE,
    DayOfWeek VARCHAR(10),
    Month VARCHAR(10),
    Quarter INT,
    Year INT,
    IsWeekend BOOLEAN
);

-- Dimension Table: DimLoyaltyProgram
CREATE TABLE DimLoyaltyProgram (
    LoyaltyProgramID INT PRIMARY KEY,
    ProgramName VARCHAR(100),
    ProgramTier VARCHAR(50),
    PointsAccrued INT
);

--DROP TABLE DIMCUSTOMER;

-- Dimension Table: DimCustomer
CREATE TABLE DimCustomer (
    CustomerID INT PRIMARY KEY autoincrement start 1 increment 1,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(20),
    DateOfBirth DATE,
    Email VARCHAR(100),
    PhoneNumber VARCHAR(100),
    Address VARCHAR(400),
    City VARCHAR(100),
    State VARCHAR(100),
    ZipCode VARCHAR(100),
    Country VARCHAR(100),
    LoyaltyProgramID INT
);

-- Dimension Table: DimProduct
CREATE TABLE DimProduct (
    ProductID INT PRIMARY KEY autoincrement start 1 increment 1,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Brand VARCHAR(50),
    UnitPrice DECIMAL(10, 2)
);

DROP TABLE DIMSTORE;
-- Dimension Table: DimStore
CREATE TABLE DimStore (
    StoreID INT PRIMARY KEY autoincrement start 1 increment 1,
    StoreName VARCHAR(100),
    StoreType VARCHAR(100),
	StoreOpeningDate DATE,
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    ZipCode VARCHAR(10),
    Country VARCHAR(100),
    Region VARCHAR(100),
    ManagerName VARCHAR(100)
);



-- Fact Table: FactOrders
CREATE TABLE FactOrders (
    OrderID INT PRIMARY KEY autoincrement start 1 increment 1,
    DateID INT,
    CustomerID INT,
    ProductID INT,
    StoreID INT,
    QuantityOrdered INT,
    OrderAmount DECIMAL(10, 2),
    DiscountAmount DECIMAL(10, 2),
    ShippingCost DECIMAL(10, 2),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (StoreID) REFERENCES DimStore(StoreID)
);

CREATE OR REPLACE FILE FORMAT CSV_SOURCE_FILE_FORMAT
TYPE = 'CSV'
SKIP_HEADER=1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
DATE_FORMAT = 'YYYY-MM-DD';

CREATE OR REPLACE STAGE TESTSTAGE;

-- PUT 'file://C:/Users/grees/Scalable Retail Data Warehouse/DATASET/DimLoyaltyInfo' @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimLoyaltyInfo/AUTO_COMPRESS=FALSE;


COPY INTO DimLoyaltyProgram
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimLoyaltyInfo/DimLoyaltyInfo.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

Select * from DIMLOYALTYPROGRAM;

-- Copying DimCustomer data with specified columns from the stage
COPY INTO DimCustomer(FirstName, LastName, Gender, DateOfBirth, Email, PhoneNumber, Address, City, State, ZipCode, Country, LoyaltyProgramID)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimCustomerData/DimCustomerData.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

-- Selecting all records from DimCustomer
SELECT * FROM DimCustomer;

-- Copying DimProduct data with specified columns from the stage
COPY INTO DimProduct(ProductName, Category, Brand, UnitPrice)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimProductData/DimProductData.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimProduct;

-- Copying DimDate data from the stage
COPY INTO DimDate(DateID, Date, DayOfWeek, Month, Quarter, Year, IsWeekend)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimDate/DimDate.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

-- Selecting all records from DimDate
SELECT * FROM DimDate;

COPY INTO DimStore(StoreName, StoreType, StoreOpeningDate, Address, City, State, Country, Region, ManagerName)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/DimStoreData/DimStoreData.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

-- Selecting all records from DimStore
SELECT * FROM DimStore;

COPY INTO FactOrders(DateID, CustomerID, ProductID, StoreID, QuantityOrdered, OrderAmount, DiscountAmount, ShippingCost, TotalAmount)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/factorders/factorders.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

-- Selecting the first 100 records from FactOrders
SELECT * FROM FactOrders LIMIT 100;

COPY INTO FactOrders(DateID, CustomerID, ProductID, StoreID, QuantityOrdered, OrderAmount, DiscountAmount, ShippingCost, TotalAmount)
FROM @TEST_DB.TEST_DB_SCHEMA.TESTSTAGE/Landing_Directory/
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM FactOrders LIMIT 100;TEST_DB.TEST_DB_SCHEMA.TESTSTAGE

-- create a new user
CREATE OR REPLACE USER Test_PowerBI_User
    PASSWORD = 'Test_PowerBI_User'
    LOGIN_NAME = 'PowerBI User'
    DEFAULT_ROLE = 'ACCOUNTADMIN'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH'
    MUST_CHANGE_PASSWORD = TRUE;

-- grant it accountadmin access
GRANT ROLE ACCOUNTADMIN TO USER Test_PowerBI_User;


