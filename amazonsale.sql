show databases;
-- create database sales;
use sales;
show tables;
Select * from salereport;
select count('Order Id') from salereport;
DESCRIBE salereport;
SHOW COLUMNS FROM salereport;
/* DATA CLEANING */
ALTER TABLE salereport DROP COLUMN `index`;
ALTER TABLE salereport DROP COLUMN `ship_date`;
ALTER TABLE SALEREPORT DROP COLUMN `UNNAMED: 22`;
ALTER TABLE salereport RENAME COLUMN `Order ID` TO order_id;
ALTER TABLE salereport RENAME COLUMN `ship-service-level` TO ship_service;
ALTER TABLE salereport RENAME COLUMN `sales channel` TO sales_channel;
ALTER TABLE salereport RENAME COLUMN `courier status` TO courier_status;
ALTER TABLE salereport RENAME COLUMN `ship-city` TO city;
ALTER TABLE salereport RENAME COLUMN `ship-state` TO state;
ALTER TABLE salereport RENAME COLUMN `ship-postal-code` TO pincode;
ALTER TABLE salereport RENAME COLUMN `ship-country` TO country;
ALTER TABLE salereport RENAME COLUMN `promotion-ids` TO promo_id;
ALTER TABLE salereport RENAME COLUMN `date` TO ship_date;
ALTER TABLE salereport MODIFY COLUMN Amount DECIMAL(10,2);
ALTER TABLE salereport ADD COLUMN temp_date DATE;
UPDATE salereport SET Amount = 0.00 WHERE Amount IS NULL;
UPDATE salereport SET city = UPPER(city);

/* Q1:Write a query to retrieve all columns for orders that have a Status of "Cancelled" and an Amount greater than 1000.*/
Select * from salereport where status like 'Cancelled' AND amount > 1000;

/*Q2:How many distinct product Style codes are present in this dataset?*/
Select distinct style from salereport;

/*Q3:Calculate the total revenue (sum of Amount) generated specifically through the "Amazon.in" Sales Channel.*/
select sum(amount) from salereport where sales_channel like 'Amazon.in';

/*Q4:What are the top 5 product Category types in terms of total revenue generated? 
Return the category name and the total revenue, sorted from highest to lowest.*/
Select Category,sum(amount * qty) as Revenue 
from salereport 
group by Category order by revenue desc limit 5;

/*Q5:Calculate the average Amount spent per order, grouped by whether it was a B2B sale (True) or a regular consumer sale (False).*/
Select B2B, AVG(Amount) from salereport group by B2B;

/*Q6:Which 3 ship_state locations received the highest total quantity (Qty) of items? Return the state name and the total quantity.*/
Select state,sum(qty) as total_qty from salereport group by state order by total_qty desc limit 3;

/*Q7:Using the newly cleaned Date column, write a query to find the total revenue generated in each month. 
Return the month (e.g., as a number or name) and the total revenue, ordered chronologically.*/
Select Sum(amount*qty) as revenue,DATE_FORMAT(ship_date, '%m') AS month from salereport group by month order by month asc;
Select Monthname(ship_date) AS month , Sum(amount*qty) as revenue from salereport group by month order by month asc;

/*Q8:Find the product Style codes that have sold a total quantity of more than 500 units, 
but have an average sale Amount of less than 400.*/
Select style, 
sum(Qty) as tot_qty, 
avg(amount) as avg_amt 
from salereport 
group by style 
having tot_qty > 500 AND avg_amt < 400 
order by tot_qty asc;

/*Q9:Write a query to calculate the total number of orders fulfilled by "Amazon" versus those fulfilled by "Merchant". 
If you want an extra challenge, try to output the percentage of total orders each fulfillment type represents.*/

Select fulfilment, sum(order_id) as tot_orders from salereport group by fulfilment;
SELECT 
    fulfilment, 
    COUNT(order_id) AS total_orders,
    (COUNT(order_id) / (SELECT COUNT(*) FROM salereport)) * 100 AS percentage
FROM salereport
GROUP BY fulfilment;

/* CTE's */
/* The Challenge: Write a query that calculates the total revenue for each month, 
and then creates a adjacent column showing the previous month's revenue using the LAG() window function. 
Finally, calculate the MoM growth percentage: */

with 
monthlyrevenue as (
SELECT 
        DATE_FORMAT(ship_date, '%Y-%m') AS month_raw, -- Best for sorting chronologically
        DATE_FORMAT(ship_date, '%b %Y') AS month_year,
        SUM(amount) AS current_month_revenue
    FROM salereport
    GROUP BY DATE_FORMAT(ship_date, '%Y-%m'), DATE_FORMAT(ship_date, '%b %Y') )
SELECT 
    month_year,
    current_month_revenue,
    LAG(current_month_revenue, 1, 0) OVER (ORDER BY month_raw) AS previous_month_revenue,
    -- Calculate MoM %
    ((current_month_revenue - LAG(current_month_revenue, 1, 0) OVER (ORDER BY month_raw)) 
    / LAG(current_month_revenue, 1, NULL) OVER (ORDER BY month_raw)) * 100 AS mom_growth_percentage
FROM MonthlyRevenue
ORDER BY month_raw ASC;

/*Create a CTE named ShippedOrders that selects the order_id, category, 
and amount from salereport but strictly filters for rows where the status is 'Shipped'.
Your Task: Write the CTE, and then write a main query that pulls the top 5 most expensive orders (highest amount)
 directly from that ShippedOrders CTE.*/
 
 With ShippedOrders as (
 Select order_id, category, amount from salereport where status = 'shipped')
 Select amount from ShippedOrders order by amount desc limit 5;
 
/* Select the order_id, ship_date, and amount from the table. 
Create a fourth column using LAG() that displays the amount of the immediately preceding order, 
ordered chronologically by ship_date. */

Select order_id, 
ship_date, 
amount, 
LAG(amount, 1, 0) over (order by amount asc) as pre_month_amount from salereport order by ship_date asc;

/* The CTE: Write a CTE named DailyKurtaSales that calculates the total quantity (SUM(qty)) of 'kurta' (from the category column) 
sold on each individual ship_date.
The Main Query: Select the ship_date and the daily total from your CTE.
The Window Function: Add a LAG() column to your main query to show the previous day's total quantity so you can compare them side-by-side. */
 With DailyKurtaSales as (
 select sum(qty) as tot_qty, 
 ship_date, 
 category from salereport 
 where category = 'kurta' group by ship_date order by tot_qty asc)
 Select ship_date, 
 tot_qty, 
 lag(ship_date,1,0) over (order by ship_date asc) as Pre_day_order from DailyKurtaSales;
 
 /* Business Goal: The inventory team needs to know which specific product category dominates 
 each regional market to optimize warehouse stocking.
The Challenge: Write a query using DENSE_RANK() or ROW_NUMBER() 
combined with OVER(PARTITION BY ...) to find the top 2 best-selling product categories (by total quantity sold) for every unique ship_state.*/

/* Rank() and Dense_rank() */
/* Your Task: Select the order_id and amount from salereport. 
Add a third column using DENSE_RANK() to rank the orders from most expensive to least expensive. */
select order_id, amount , dense_rank() over (partition by category order by amount desc) as Expense_rank from salereport limit 10;

/*Select category, style, and qty. Add a fourth column using RANK() that ranks the rows by highest qty. 
Crucially, use PARTITION BY so that the ranking restarts at 1 for every new category. */
Select category, style, qty, rank() over ( partition by category order by qty desc) as Qty_rank from salereport limit 10;

/*The CTE: Create a CTE that groups the data by ship_state and ship_city, 
and calculates the total quantity (SUM(qty)) sold in each city.
The Main Query: Query your CTE. Select the state, city, and total quantity. 
Add a DENSE_RANK() column that ranks the cities by total quantity (highest to lowest), partitioned by state.*/
With Address as (
Select 
state, 
city, 
sum(qty) as Tot_Qty 
from salereport 
GROUP BY state, city
)
Select 
state, 
city, 
Tot_Qty, 
Dense_rank() over (partition by state order by Tot_Qty desc) as City_rank 
from address;

/* Take the exact Address CTE you just wrote (the one that ranks cities by total quantity within each state).
In your main query, select the state, city, total quantity, and rank.
Add a WHERE clause to your main query so it only outputs the cities that ranked 1, 2, or 3.*/
With Address as (
Select 
state, 
city, 
sum(qty) as Tot_Qty 
from salereport 
GROUP BY state, city
),
Cityrank as (
Select 
state, 
city, 
Tot_Qty, 
Dense_rank() over (partition by state order by Tot_Qty desc) as City_rank 
from address)

Select state,city, city_rank from cityrank where city_rank <= 3;

/*The CTE: Create a CTE named DailyRevenue that groups by ship_date and calculates the total SUM(amount) for each day.
The Main Query: Select the ship_date and daily revenue from your CTE.
Add a third column using SUM(daily_revenue) OVER (ORDER BY ship_date ASC) to create a running total that grows chronologically.*/
with DailyRevenue as (
Select ship_date, sum(amount) as tot_amt from salereport group by ship_date)
select ship_date, tot_amt, sum(tot_amt) over (order by ship_date asc) as Tot from dailyRevenue;

/*The CTE: Select category, order_id, and ship_date. Create a ROW_NUMBER() column, partitioned by category and ordered by ship_date ASC.
The Main Query: Query your CTE and filter it to only show rows where the row number is 1.*/
with Product_category as (
Select category, 
order_id, 
ship_date, 
row_number() over (partition by category order by ship_date ASC)as Prod_num 
from salereport)
Select category, order_id,Prod_num from Product_category where prod_num = 1;

/* Business Goal: The inventory team needs to know which specific product category dominates 
each regional market to optimize warehouse stocking.
The Challenge: Write a query using DENSE_RANK() or ROW_NUMBER() combined with OVER(PARTITION BY ...) to 
find the top 2 best-selling product categories (by total quantity sold) for every unique ship_state.*/
WITH CategorySales AS (
    -- Step 1: Find the total quantity for each category, in every state
    SELECT 
        state, 
        category, 
        SUM(qty) AS total_qty
    FROM salereport
    GROUP BY state, category
),
RankedCategories AS (
    -- Step 2: Rank them within each state
    SELECT 
        state, 
        category, 
        total_qty,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY total_qty DESC) AS Prod_rank
    FROM CategorySales
)
-- Step 3: Filter for the Top 2
SELECT 
    state, 
    category,
    total_qty,
    Prod_rank 
FROM RankedCategories 
WHERE Prod_rank <= 2;
/*First, in the CTE, calculate the total spending (SUM(Amount)) and total items purchased (SUM(Qty)) for every individual Order ID.
Second, in your main query pulling from that CTE, select only the orders where the 
total spent is in the top 5% of all orders database-wide. 
(Hint: You can use the PERCENT_RANK() window function or a subquery to find the 95th percentile threshold).*/
With TotalSpending As(
Select order_id, Sum(amount) as Tot_Amount, Sum(Qty) as Tot_Qty from salereport group by order_id),
IndividualOrder As(
Select order_id, Tot_Amount, Tot_Qty, percent_rank() over (order by Tot_Amount) as Percent_Amt from TotalSpending)
Select order_id, Tot_Amount, Tot_Qty, Percent_Amt from IndividualOrder where Percent_Amt >= 0.95;

/*Regional managers need to know which cities are driving their state's performance.
For each city, calculate its total revenue. Then, calculate what percentage that city contributes to the overall state's total revenue.
Step 1 (CTE): Find the total revenue per city (SUM(amount) grouped by state and city).
Step 2 (Main Query): You need to divide the city's revenue by the state's total revenue. 
To get the state's total without collapsing the city rows, you use a windowed sum: SUM(city_revenue) OVER (PARTITION BY state).*/
WITH CityRevenue AS (
    -- Step 1: Get the revenue for each city
    SELECT 
        city, 
        state, 
        SUM(amount) AS Revenue 
    FROM salereport 
    GROUP BY city, state
)
-- Step 2: Calculate the share of the state total
SELECT 
    city, 
    state, 
    Revenue, 
    SUM(Revenue) OVER (PARTITION BY state) AS State_Total,
    (Revenue / SUM(Revenue) OVER (PARTITION BY state)) * 100 AS Percent_of_State_Total
FROM CityRevenue order by state asc;

/*The Grand Total (Empty OVER)
If you leave the parentheses blank, SQL calculates the math for the entire dataset and pastes that exact same grand total on every single row.
Example: You want to see every individual order side-by-side with the company's total overall revenue.*/
SELECT 
    order_id, 
    amount, 
    SUM(amount) OVER () AS company_grand_total
FROM salereport;

/*This is what you saw in Challenge 1. When you partition by a column, SQL calculates the math only for that specific group, 
and pastes that subtotal next to the relevant rows.
Example: You want to see individual orders, but you also want to know the average order size for that specific product 
category to see if a customer over-performed or under-performed.*/
SELECT 
    order_id, 
    category,
    amount, 
    AVG(amount) OVER (PARTITION BY category) AS avg_category_amount
FROM salereport;
/*When you add an ORDER BY inside a window aggregate, it changes the math entirely. 
Instead of giving you a static total for the group, it calculates a cumulative tally that grows row by row according to the order you set.
Example: You want to watch the revenue grow day by day.*/
SELECT 
    ship_date, 
    amount, 
    SUM(amount) OVER (ORDER BY ship_date ASC) AS cumulative_revenue
FROM salereport;

/* The Scenario: The pricing team wants to see how every individual order stacks up against the 
absolute most expensive order placed within that same product category.
Your Task:Select order_id, category, and amount from salereport.
Add a fourth column using MAX(amount) as a window aggregate.
Use PARTITION BY so the maximum amount resets for every category.*/
Select order_id, category, amount,
MAX(amount) over (partition by category) As max_amount_catergory from salereport;

/*The Scenario: You are looking at a specific day's sales (e.g., April 15th), 
and you want to see every order placed that day, alongside the grand total revenue for that entire day.
Your Task:Select order_id, category, and amount.
Add a fourth column using SUM(amount) OVER (). (Leave the parentheses empty!)
Add a standard WHERE clause at the very end to filter for just one day: WHERE ship_date = '2022-04-15'.*/
Select order_id, category, amount,
SUM(amount) over() as Overall_Sale from salereport where ship_date = '2022-04-15';

/*The Scenario: The finance team wants to watch the average order size fluctuate day by day over the course of the 
month to see if order sizes are growing or shrinking over time.
Your Task:Select order_id, ship_date, and amount.
Add a fourth column using AVG(amount) as a window aggregate.
Inside the OVER() clause, use ORDER BY ship_date ASC.*/
Select order_id, ship_date, amount,
AVG(amount) over ( order by ship_date) as Diff_avg_amount from salereport;

/*The Scenario: You already calculated a running average for the entire company. Now, the product team wants to watch the 
cumulative revenue grow day by day,but they want a separate running total for each individual product category.
Your Task:Select category, ship_date, and amount.
Add a fourth column using SUM(amount) as your aggregate.
Inside your OVER() clause, use both PARTITION BY category and ORDER BY ship_date ASC.*/
Select category, ship_date, amount, Sum(amount) over (partition by category order by ship_date asc) as Cum_revenue from salereport;

/*The Scenario: The fulfillment center wants to look at a list of individual orders and instantly see the 
total volume of boxes heading to that exact state, so they can plan their truck loads.*/
Select state,order_id,ship_date,sum(qty) over (partition by state) as Tot_volume from salereport;

/*The Scenario: The pricing strategy team wants to measure variance. For every order, 
they want to see exactly how much cheaper it was compared to the absolute most expensive order in that same category.*/
With fun as (Select order_id, category, amount, MAX(amount) over (partition by category) as max_order from salereport)
Select order_id, category, amount, max_order, (max_order - amount) as diff_amount from fun;

/*The Goal: Break all orders into 4 equal tiers (Quartiles) based on the total amount spent, from highest to lowest.
The Clues: Select order_id and amount, and use the NTILE(4) window function, ordered by amount DESC.*/
Select order_id, amount, ntile(4) over ( order by amount desc) as split_grps from salereport;














