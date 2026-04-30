create database sales_profitability_data;
use sales_profitability_data;

CREATE TABLE DimStore (
Store_ID VARCHAR(10) PRIMARY KEY,
Store_Name VARCHAR(100) NOT NULL,
Region VARCHAR(50),
City VARCHAR(50),
Store_Size INT,
Manager_name varchar(50),
Open_since date,
Monthly_Rent DECIMAL(12,2),
Staff_Count INT,
Is_Active BIT
);

CREATE TABLE DimProduct (
Product_ID VARCHAR(10) PRIMARY KEY,
Product_Name VARCHAR(150) NOT NULL,
Category VARCHAR(50),
Sub_Category VARCHAR(50),
Supplier_ID varchar(10),
Cost_Price DECIMAL(10,2),
MRP DECIMAL(10,2),
validation_column varchar(20),
Stock_Units INT,
Reorder_level int,
Brand VARCHAR(100),
GST_Rate_Pct INT,
Is_perishable varchar(20)
);

CREATE TABLE DimCustomer (
Customer_ID VARCHAR(10) PRIMARY KEY,
First_Name VARCHAR(50),
Last_Name VARCHAR(50),
Email VARCHAR(150),
Email_status varchar(20),
Phone INT,
Phone_number INT,
phone_status varchar(20),
City VARCHAR(50),
Loyalty_Tier VARCHAR(20),
Registration_date date,
Total_purchases INT,
Lifetime_Value DECIMAL(12,2),
Age INT,
Gender VARCHAR(10)
);

CREATE TABLE DimDate (
DateKey DATE PRIMARY KEY,
Year INT,
Quarter INT,
Month INT,
MonthName VARCHAR(20),
Week INT,
DayOfWeek VARCHAR(15),
IsWeekend BIT
);

CREATE TABLE Fact_Sales (
Transaction_ID VARCHAR(15) PRIMARY KEY,
Customer_ID VARCHAR(10),
Store_ID VARCHAR(10),
Product_ID VARCHAR(10),
Product_name varchar(50),
Category varchar(50),
Date DATE,
Quantity INT,
Unit_Price DECIMAL(10,2),
Status varchar(20),
Discount_Pct DECIMAL(5,2),
Cost_Per_Unit DECIMAL(10,2),
Payment_Method VARCHAR(30)
);

CREATE TABLE Fact_MonthlyProfitability (
Store_ID VARCHAR(10),
Month VARCHAR(7),
Gross_Revenue DECIMAL(14,2),
COGS DECIMAL(14,2),
Gross_Profit DECIMAL(14,2),
Operating_expenses decimal(14,2),
Net_Profit DECIMAL(14,2),
Gross_Margin_Pct DECIMAL(6,2),
Net_Margin_Pct DECIMAL(6,2),
Transactions_Count INT,
Avg_Basket_Size int,
Returns_amount INT,
PRIMARY KEY (Store_ID, Month)
);

-- 1.SELECT TOP 10 *
SELECT * FROM DimStore order by staff_count desc limit 10;
select * from dimcustomer order by Lifetime_Value desc limit 10;
select * from dimproduct order by MRP desc limit 10;
select * from fact_sales order by Cost_Per_Unit desc limit 10;
select * from fact_monthlyprofitability order by Gross_Revenue desc limit 10;

-- 2.Add constraints
ALTER TABLE Fact_Sales
ADD CONSTRAINT fk_store FOREIGN KEY (Store_ID) REFERENCES dimstore(Store_ID);

ALTER TABLE Fact_Sales
ADD CONSTRAINT fk_product FOREIGN KEY (Product_ID) REFERENCES dimproduct(Product_ID);

ALTER TABLE Fact_Sales
ADD CONSTRAINT fk_customer FOREIGN KEY (Customer_ID) REFERENCES dimcustomer(Customer_ID);

-- 3. check the joins 
SELECT 
f.Transaction_ID,
f.Date,
s.Store_Name,
s.Region,
f.Unit_Price,
f.Quantity
FROM Fact_Sales f
INNER JOIN DimStore s ON f.Store_ID = s.Store_ID;

-- 4. test join on three tables  

select 
f.customer_ID,
f.product_name,
s.store_name,
f.date,
p.category,
c.email from fact_sales f 
JOIN dimcustomer c on f.Customer_ID = c.Customer_ID
JOIN dimproduct p on f.Product_ID = p.Product_ID
JOIN dimstore s on f.Store_ID = s.Store_ID;