--create_copy
-- Copy a table to create a new one
CREATE OR REPLACE TABLE `sql-demonstration.Super_Market_sales.sales_record_edited` AS
SELECT *
FROM `sql-demonstration.Super_Market_sales.sales_record`;
--------------------------------------------------------------------------------------------
--null_count 
SELECT
  COUNTIF(Date IS NULL) AS Null_Date,
  COUNTIF(Time IS NULL) AS Null_Time,
  COUNTIF(Item_Code IS NULL) AS Null_Item_Code,
  COUNTIF(Quantity_Sold__kilo_ IS NULL) AS Null_Quantity_Sold_kilo,
  COUNTIF(Unit_Selling_Price__RMB_kg_ IS NULL) AS Null_Unit_Selling_Price_RMB_kg,
  COUNTIF(Sale_or_Return IS NULL) AS Null_Sale_or_Return,
  COUNTIF(Discount__Yes_No_ IS NULL) AS Null_Discount
FROM
  `sql-demonstration.Super_Market_sales.sales_record_edited`;

--------------------------------------------------------------------------------------------
--negative_quantity
SELECT COUNTIF(Quantity_Sold__kilo_ < 0) AS Negative_Quantity_Count
FROM `sql-demonstration.Super_Market_sales.sales_record_edited`;
--------------------------------------------------------------------------------------------
--change_to_positive
UPDATE `sql-demonstration.Super_Market_sales.sales_record_edited`
SET Quantity_Sold__kilo_ = ABS(Quantity_Sold__kilo_)
WHERE Quantity_Sold__kilo_ < 0;
--------------------------------------------------------------------------------------------
--total_cost
SELECT
  Quantity_Sold__kilo_ * Unit_Selling_Price__RMB_kg_ AS total_cost
FROM
  `sql-demonstration.Super_Market_sales.sales_record_edited`;
--------------------------------------------------------------------------------------------
--date_to_weekday
SELECT
  Date,
  FORMAT_DATE('%A', DATE(Date)) AS day_of_week
FROM
  `sql-demonstration.Super_Market_sales.sales_record_edited`;
--------------------------------------------------------------------------------------------
--update_for_weekday
-- Step 1: Add a new column to the dataset
ALTER TABLE `sql-demonstration.Super_Market_sales.sales_record_edited`
ADD COLUMN day_of_week STRING;

-- Step 2: Update the new column with day of the week values
UPDATE `sql-demonstration.Super_Market_sales.sales_record_edited`
SET day_of_week = FORMAT_DATE('%A', DATE(Date));
--------------------------------------------------------------------------------------------
--Daily_revenue
-- Step 1: Calculate total_cost
WITH TotalCost AS (
  SELECT
    Date,
    Quantity_Sold__kilo_,
    Unit_Selling_Price__RMB_kg_,
    Quantity_Sold__kilo_ * Unit_Selling_Price__RMB_kg_ AS total_cost
  FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited`
)

-- Step 2: Calculate daily revenue
SELECT
  Date,
  SUM(total_cost) AS Total_Revenue
FROM
  TotalCost
GROUP BY
  Date
ORDER BY
  Date;
--------------------------------------------------------------------------------------------
--monthly_revenue
-- Step 1: Calculate total_cost
WITH TotalCost AS (
  SELECT
    Date,
    Quantity_Sold__kilo_,
    Unit_Selling_Price__RMB_kg_,
    Quantity_Sold__kilo_ * Unit_Selling_Price__RMB_kg_ AS total_cost
  FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited`
)

-- Step 2: Calculate monthly revenue
SELECT
  EXTRACT(YEAR FROM Date) AS Year,
  EXTRACT(MONTH FROM Date) AS Month,
  SUM(total_cost) AS Total_Revenue
FROM
  TotalCost
GROUP BY
  Year, Month
ORDER BY
  Year, Month;
--------------------------------------------------------------------------------------------#
--monthly_highest_selling_products
-- Step 1: Calculate total_cost
WITH TotalCost AS (
  SELECT
    Date,
    Item_Code,
    Quantity_Sold__kilo_,
    Unit_Selling_Price__RMB_kg_,
    Quantity_Sold__kilo_ * Unit_Selling_Price__RMB_kg_ AS total_cost
  FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited`
)

-- Step 2: Extract year and month
, YearMonth AS (
  SELECT
    EXTRACT(YEAR FROM Date) AS Year,
    EXTRACT(MONTH FROM Date) AS Month,
    Item_Code,
    SUM(total_cost) AS Total_Revenue
  FROM
    TotalCost
  GROUP BY
    Year, Month, Item_Code
)

-- Step 3: Rank products by monthly sales
, RankedProducts AS (
  SELECT
    Year,
    Month,
    Item_Code,
    Total_Revenue,
    RANK() OVER (PARTITION BY Year, Month ORDER BY Total_Revenue DESC) AS Rank
  FROM
    YearMonth
)

-- Step 4: Join with item_code_and_category to get product names
SELECT
  r.Year,
  r.Month,
  r.Item_Code,
  ic.Item_Name AS Product_Name,
  r.Total_Revenue
FROM
  RankedProducts r
JOIN
  `sql-demonstration.Super_Market_sales.item_code_and_category` ic
ON
  r.Item_Code = ic.Item_Code
WHERE
  r.Rank = 1
ORDER BY
  r.Year, r.Month;
--------------------------------------------------------------------------------------------
--daily_sale_of_product
-- Filter rows for "Product" and calculate daily sales
WITH ProductSales AS (
SELECT
    Date,
    SUM(Quantity_Sold__kilo_) AS Daily_Sales
FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited`
WHERE
    Item_Code IN (
    SELECT
        Item_Code
    FROM
        `sql-demonstration.Super_Market_sales.item_code_and_category`
    WHERE
        Item_Name = "Broccoli"
    )
GROUP BY
    Date
)

-- Show daily sales of "Product"
SELECT
Date,
Daily_Sales
FROM
ProductSales
ORDER BY
Date;
--------------------------------------------------------------------------------------------
--daily_price
-- Filter rows for your product with non-discount prices and retrieve distinct Unit_Selling_Price__RMB_kg_
SELECT DISTINCT
Date,
Unit_Selling_Price__RMB_kg_
FROM
`sql-demonstration.Super_Market_sales.sales_record_edited`
WHERE
Item_Code IN (
    SELECT
    Item_Code
    FROM
    `sql-demonstration.Super_Market_sales.item_code_and_category`
    WHERE
    Item_Name = "{product}"
)
AND Discount__Yes_No_ = false
ORDER BY
Date;
--------------------------------------------------------------------------------------------
--daily_category_revenue_contribution
-- Calculate daily revenue per category
WITH CategoryRevenue AS (
  SELECT
    s.Date,
    ic.Category_Name,
    SUM(s.Quantity_Sold__kilo_ * s.Unit_Selling_Price__RMB_kg_) AS Daily_Revenue
  FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited` AS s
  JOIN
    `sql-demonstration.Super_Market_sales.item_code_and_category` AS ic
  ON
    s.Item_Code = ic.Item_Code
  WHERE
    s.Discount__Yes_No_ = false
  GROUP BY
    s.Date, ic.Category_Name
)

-- Pivot the data for selected categories
SELECT
  Date,
  MAX(IF(Category_Name = 'Aquatic Tuberous Vegetables', Daily_Revenue, NULL)) AS Aquatic_Tuberous_Vegetables,
  MAX(IF(Category_Name = 'Cabbage', Daily_Revenue, NULL)) AS Cabbage,
  MAX(IF(Category_Name = 'Capsicum', Daily_Revenue, NULL)) AS Capsicum,
  MAX(IF(Category_Name = 'Edible Mushroom', Daily_Revenue, NULL)) AS Edible_Mushroom,
  MAX(IF(CAST(Category_Name AS STRING) LIKE '%Flower/Leaf%Vegetables%', Daily_Revenue, NULL)) AS Flower_Leaf_Vegetables,
  MAX(IF(Category_Name = 'Solanum', Daily_Revenue, NULL)) AS Solanum
FROM
  CategoryRevenue
GROUP BY
  Date
ORDER BY
  Date;
  --------------------------------------------------------------------------------------------
--daily_category_revenue_for_area_chart
-- Calculate daily revenue per category
WITH CategoryRevenue AS (
  SELECT
    s.Date,
    ic.Category_Name,
    SUM(s.Quantity_Sold__kilo_ * s.Unit_Selling_Price__RMB_kg_) AS Daily_Revenue
  FROM
    `sql-demonstration.Super_Market_sales.sales_record_edited` AS s
  JOIN
    `sql-demonstration.Super_Market_sales.item_code_and_category` AS ic
  ON
    s.Item_Code = ic.Item_Code
  WHERE
    s.Discount__Yes_No_ = false
  GROUP BY
    s.Date, ic.Category_Name
)
-- Summarize daily revenue per category
SELECT
  Date,
  Category_Name,
  SUM(Daily_Revenue) AS Category_Daily_Revenue
FROM
  CategoryRevenue
GROUP BY
  Date, Category_Name
ORDER BY
  Date, Category_Name;

