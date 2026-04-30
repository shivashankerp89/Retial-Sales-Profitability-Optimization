use sales_profitability_data;

-- KPI queries;

select count(*) from dimstore union all
select count(*) from dimproduct union all
select count(*) from dimcustomer union all
select count(*) from fact_sales union all
select count(*) from fact_monthlyprofitability;

-- 1. find the master KPI'S - revenue,cogs,profit for each transaction
select 
c.first_name,
f.transaction_ID,
f.date,
s.store_id,
s.region,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as profit 
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID;

-- 2. find the gross margin % 

select 
c.first_name,
f.transaction_ID,
f.date,
s.store_id,
s.region,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit ,

round( 
       case
            when (f.unit_price*f.quantity*(1-discount_pct)) = 0 then 0
            else (
				   (((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit))
                   /
                   (f.unit_price*f.quantity*(1-discount_pct)))*100)
            end
      ,2)       as gross_margin
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID;

-- 3. wrap this master query using the CTE
WITH saleskpi as(
select 
c.first_name,
f.transaction_ID,
f.date,
s.store_id,
s.region,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select 
first_name,
transaction_ID,
date,
store_id,
region,
product_name,
quantity,
unit_price,
discount_pct,
cost_per_unit,
revenue,COGS,gross_profit,
round(  
       case
            when revenue = 0 then 0
            else (gross_profit/revenue)*100 
            end
            ,2) as  gross_margin
from saleskpi sc ;

-- 4. Revenue,margin,transaction count,basket size aggregated by Store,region
WITH saleskpi as(
select 
c.first_name,
f.transaction_ID,
f.date,
s.store_id,
s.region,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select
store_id,
region,
sum(revenue) as total_revenue,
sum(gross_profit) as total_profit,
round((sum(gross_profit)/sum(revenue))*100,2) as total_gross_profit ,
round(count(transaction_id),2) as transactions_count ,
round(sum(revenue)/count(transaction_id),2) as avg_basket_size
from saleskpi group by store_id,region;

-- 5.Revenue and margin aggregated by Category
WITH saleskpi as(
select 
c.first_name,
f.category,
f.transaction_ID,
f.date,
s.store_id,
s.region,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select
category,
sum(revenue) as total_revenue,
sum(gross_profit) as total_profit,
round((sum(gross_profit)/sum(revenue))*100,2) as total_gross_profit ,
round(count(transaction_id),2) as transactions_count ,
round(sum(quantity),2) as total_quantity
from saleskpi group by category
order by total_gross_profit,total_profit desc;
  
-- 6.Monthly revenue trend — GROUP BY Year, MonthName
WITH saleskpi as(
select 
c.first_name,
f.category,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select
yyyy,mm,
sum(revenue) as total_revenue,
sum(gross_profit) as total_profit,
round((sum(gross_profit)/sum(revenue))*100,2) as total_gross_profit ,
round(count(transaction_id),2) as transactions_count ,
round(sum(quantity),2) as total_quantity
from saleskpi group by yyyy,mm_nm,mm
order by yyyy,mm_nm asc;

-- 7.Revenue by Loyalty Tier and Payment Method
WITH saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select
loyalty_tier,payment_method,count(distinct customer_id) as customers,
sum(revenue) as total_revenue,
sum(gross_profit) as total_profit,
round((sum(gross_profit)/sum(revenue))*100,2) as total_gross_profit ,
round(count(transaction_id),2) as transactions_count ,
round(sum(quantity),2) as total_quantity
from saleskpi group by loyalty_tier,payment_method;

-- 8. ABC analysis 
WITH saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
),
product_rev as (
select product_id,
sum(revenue) as product_revenue
from saleskpi group by product_id
),
productcumulative as (
select *,
sum(product_revenue) over (order by product_revenue desc) as cumu,
sum(product_revenue) over() as total_rev
from product_rev
)
select *,
round((cumu/total_rev)*100,2) as pct,
case
     when (cumu/total_rev) <= 0.70 then "A"
     when (cumu/total_rev) <= 0.90 then "B"
     else "C"
     end as tier
from productcumulative
order by product_revenue desc;



-- practice window functions

WITH saleskpi AS (
SELECT 
YEAR(f.date) AS yyyy,
MONTH(f.date) AS mm_nm,
MONTHNAME(f.date) AS mm,
ROUND(f.unit_price*f.quantity*(1 - f.discount_pct),2) AS revenue
FROM fact_sales f
),

monthly_data AS (
SELECT 
yyyy,
mm_nm,
mm,
SUM(revenue) AS monthly_revenue
FROM saleskpi
GROUP BY yyyy, mm_nm, mm
)

SELECT 
yyyy,
mm,
monthly_revenue,
SUM(monthly_revenue) OVER (ORDER BY yyyy, mm_nm) AS running_total,
SUM(monthly_revenue) OVER () AS total_revenue
FROM monthly_data
ORDER BY yyyy, mm_nm;

-- 9. Rank() stores by average net margin pct
select store_id,
sum(gross_revenue) as total_gross_revenue,
sum(net_profit) as total_profit,
round(avg(net_margin_pct),2) as avg_net_margin_pct,
rank() over(order by avg(net_margin_pct) desc) as rank_store,
case 
when rank() over(order by avg(net_margin_pct) desc) <=3 then 'top'
when rank() over(order by avg(net_margin_pct) desc) >=8 then 'low'
else 'average'
end as catergory
from fact_monthlyprofitability
group by store_id
order by rank_store;

-- 10.customer RFM segmentation 
with saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
),
RFM as(
select 
customer_id,
datediff(curdate(),max(Date)) as racency_days,
max(date),
count(transaction_id) as transactions_count,
sum(revenue) as total_revenue
from saleskpi group by customer_id
),
find as(
select *,
ntile(4) over(order by racency_days desc) as R_score,
ntile(4) over(order by transactions_count asc) as F_score,
ntile(4) over(order by total_revenue asc) as M_score
from RFM
)
select customer_id,racency_days,transactions_count,total_revenue,
R_score,
F_score,
M_score,
case 
when R_score=4 and F_score>=3 then 'champion'
when R_score>=2 and F_score>=2 then 'loyal'
when R_score>=3 and F_score>=2 then 'new customer'
when R_score<=1 and F_score<=4 then 'at risk'
else 'need re-engagemnet'
end category_segment
from find;

-- 11. top 10 and bottom 10 products by gross margin 
-- top 10
with saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select product_name,sum(revenue),sum(gross_profit),
round((sum(gross_profit)/sum(revenue))*100,2) as gross_margin
from saleskpi group by product_name order by gross_margin desc limit 10;

-- bottom 10
with saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select product_name,sum(revenue),sum(gross_profit),
round((sum(gross_profit)/sum(revenue))*100,2) as gross_margin
from saleskpi group by product_name order by gross_margin asc limit 10;

-- 12. discount impact analysis 
with saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
)
select 
case
when discount_pct = 0 then ' no discount'
when discount_pct <= 0.10 then 'low 10%'
when discount_pct <=0.25 then 'medium 10-25%'
else 'high 25%+' end as discount_band ,
sum(revenue) as total_rev,
count(*) as transactions,
round((avg(gross_profit/revenue)*100),2) as avg_margin_pct
from saleskpi group by 
case when discount_pct = 0 then ' no discount'
when discount_pct <= 0.10 then 'low 10%'
when discount_pct <=0.25 then 'medium 10-25%'
else 'high 25%+' end
order by avg_margin_pct;

-- 13.create view for store data
create view vw_storeperformance as
select 
s.store_id,s.store_name,s.region,s.city,s.staff_count,s.store_size,
round(sum(
(f.quantity*f.unit_price*(1-f.discount_pct))),2) as gross_revenue ,

round(sum(
(f.quantity*f.unit_price*(1-f.discount_pct)) - (f.quantity*f.cost_per_unit)),2) as gross_profit,

count(f.transaction_id) as total_transactions,

round(sum(f.quantity*f.unit_price*(1-f.discount_pct))/count(f.transaction_id),2) as avg_basket_size

from fact_sales f 
join dimstore s on s.store_id=f.store_id
group by
s.store_id,
s.store_name,
s.region,
s.city,
s.staff_count,
s.store_size;

SELECT * FROM vw_storeperformance;
DROP VIEW vw_storeperformance;

-- create the product abc tier view
create view product_abc_view as 
WITH saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
),
product_rev as (
select product_id,
sum(revenue) as product_revenue
from saleskpi group by product_id
),
productcumulative as (
select *,
sum(product_revenue) over (order by product_revenue desc) as cumu,
sum(product_revenue) over() as total_rev
from product_rev
)
select *,
round((cumu/total_rev)*100,2) as pct,
case
     when (cumu/total_rev) <= 0.70 then "A"
     when (cumu/total_rev) <= 0.90 then "B"
     else "C"
     end as tier
from productcumulative
order by product_revenue desc;
select * from product_abc_view;

-- create view for customer summary RFM view
create view customer_rfm_view as 
with saleskpi as(
select 
c.first_name,
c.customer_id,
c.loyalty_tier,
f.category,
f.payment_method,
f.transaction_ID,
f.date,
year(f.date) as yyyy,
monthname(f.date) as mm,
month(f.date) as mm_nm,
s.store_id,
p.product_name,
f.quantity,
f.unit_price,
f.discount_pct,
f.cost_per_unit,
f.product_id,
round(f.unit_price*f.quantity*(1-discount_pct),2) as revenue ,
round(f.quantity*f.cost_per_unit,2) as COGS ,
round((f.unit_price*f.quantity*(1-discount_pct)) - (f.quantity*f.cost_per_unit),2) as gross_profit
from fact_sales f join dimstore s on s.store_id = f.store_id 
join dimproduct p on p.product_id = f.product_id 
join dimcustomer c on c.customer_id = f.customer_ID
),
RFM as(
select 
customer_id,
datediff(curdate(),max(Date)) as racency_days,
max(date),
count(transaction_id) as transactions_count,
sum(revenue) as total_revenue
from saleskpi group by customer_id
),
find as(
select *,
ntile(4) over(order by racency_days desc) as R_score,
ntile(4) over(order by transactions_count asc) as F_score,
ntile(4) over(order by total_revenue asc) as M_score
from RFM
)
select customer_id,racency_days,transactions_count,total_revenue,
R_score,
F_score,
M_score,
case 
when R_score=4 and F_score>=3 then 'champion'
when R_score>=2 and F_score>=2 then 'loyal'
when R_score>=3 and F_score>=2 then 'new customer'
when R_score<=1 and F_score<=4 then 'at risk'
else 'need re-engagemnet'
end category_segment
from find;
select * from customer_rfm_view;

-- create a view for monthly trend 
create view month_trend as 
SELECT
year(date),month(date),monthname(date),quarter(date),
SUM(Quantity*Unit_Price*(1-Discount_Pct)) AS Revenue,
SUM((Quantity*Unit_Price*(1-Discount_Pct))
-Quantity*Cost_Per_Unit) AS Gross_Profit,
COUNT(Transaction_ID) AS Transactions
FROM Fact_Sales 
GROUP BY year(date),month(date),monthname(date),quarter(date)
order by year(date),month(date);
select * from month_trend;
drop view month_trend;

SELECT COUNT(*), SUM(gross_Revenue) FROM vw_StorePerformance;
select count(*),sum(revenue) from month_trend;
select count(*),sum(total_revenue) from customer_rfm_view;