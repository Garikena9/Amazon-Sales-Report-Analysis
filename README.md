# Amazon-Ecommerce-SQL-Analysis
## Project Overview
This project uses advanced SQL to analyze e-commerce sales data, translating ambiguous business questions into actionable logistical and marketing insights. The analysis focuses on inventory optimization, customer segmentation, and supply chain efficiency.

## Technical Skills Demonstrated
* **Advanced Window Functions:** `PERCENT_RANK()`, `NTILE()`, `LAG()`, Windowed Aggregates
* **Complex Data Modeling:** Chained Common Table Expressions (CTEs)
* **Data Aggregation & Grouping**

## Business Problems Solved

### 1. Inventory Optimization (Top Categories)
* **The Ask:** Identify the top 2 best-selling product categories for every unique shipping state to optimize regional warehouse stocking.
* **The Solution:** Utilized a chained CTE structure with `DENSE_RANK()` and `PARTITION BY` to rank categories by total quantity sold within each state.

### 2. Marketing Segmentation (Customer Tiers)
* **The Ask:** Break all orders into four equal tiers (Quartiles) based on total amount spent to establish cutoffs for a new loyalty program.
* **The Solution:** Leveraged the `NTILE(4)` window function to evenly distribute and categorize spending brackets.

### 3. Supply Chain Tracking (Order Restocking Gaps)
* **The Ask:** Calculate the days elapsed between orders for specific categories to forecast restocking timelines.
* **The Solution:** Applied the `LAG()` function combined with date math to find the precise gap between chronological orders. 

## Dataset
*A synthetic Amazon sales dataset containing shipment date, Status, Fulfilment, sales channel, shipment service, Style, category, size, courier status, Qty, currency, Amount...etc 

