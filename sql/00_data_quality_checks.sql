-- 1. Liczebność i unikalność identyfikatorów w źródle
SELECT COUNT(*) AS Rows_Total, COUNT(DISTINCT Product_ID) AS Unique_Product_ID
FROM staging_products;

SELECT COUNT(*) AS Rows_Total, COUNT(DISTINCT Customer_ID) AS Unique_Customer_ID
FROM staging_customers;

SELECT COUNT(*) AS Rows_Total, COUNT(DISTINCT Order_ID) AS Unique_Order_ID
FROM staging_sales;

-- 2. niedopasowane identyfikatory
SELECT COUNT(*) AS Missing_Products
FROM staging_sales s
LEFT JOIN staging_products p ON s.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

SELECT COUNT(*) AS Missing_Customers
FROM staging_sales s
LEFT JOIN staging_customers c ON s.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;

-- 3. Brakujące pola opisowe produktów
SELECT
    SUM(CASE WHEN Product_ID IS NULL OR Product_ID = '' THEN 1 ELSE 0 END) AS Missing_Product_ID,
    SUM(CASE WHEN Product_Name IS NULL OR Product_Name = '' THEN 1 ELSE 0 END) AS Missing_Product_Name,
    SUM(CASE WHEN Category IS NULL OR Category = '' THEN 1 ELSE 0 END) AS Missing_Category,
    SUM(CASE WHEN Brand IS NULL OR Brand = '' THEN 1 ELSE 0 END) AS Missing_Brand
FROM staging_products;

-- 4. Sprawdzenie możliwości konwersji z tekstu na liczbę
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN TRY_CONVERT(decimal(12,2), Original_Price) IS NULL
                 AND Original_Price IS NOT NULL AND Original_Price <> ''
             THEN 1 ELSE 0 END) AS Invalid_Original_Price,
    SUM(CASE WHEN TRY_CONVERT(decimal(5,2), Discount_Percent) IS NULL
                 AND Discount_Percent IS NOT NULL AND Discount_Percent <> ''
             THEN 1 ELSE 0 END) AS Invalid_Discount_Percent,
    SUM(CASE WHEN TRY_CONVERT(decimal(12,2), Selling_Price) IS NULL
                 AND Selling_Price IS NOT NULL AND Selling_Price <> ''
             THEN 1 ELSE 0 END) AS Invalid_Selling_Price
FROM staging_products;

SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN TRY_CONVERT(int, Age) IS NULL
                 AND Age IS NOT NULL AND Age <> '' THEN 1 ELSE 0 END) AS Invalid_Age,
    SUM(CASE WHEN TRY_CONVERT(date, Date_of_Birth) IS NULL
                 AND Date_of_Birth IS NOT NULL AND Date_of_Birth <> '' THEN 1 ELSE 0 END) AS Invalid_Birth_Date,
    SUM(CASE WHEN TRY_CONVERT(date, Registration_Date) IS NULL
                 AND Registration_Date IS NOT NULL AND Registration_Date <> '' THEN 1 ELSE 0 END) AS Invalid_Registration_Date
FROM staging_customers;

SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN TRY_CONVERT(date, Order_Date) IS NULL
                 AND Order_Date IS NOT NULL AND Order_Date <> '' THEN 1 ELSE 0 END) AS Invalid_Order_Date,
    SUM(CASE WHEN TRY_CONVERT(time, Order_Time) IS NULL
                 AND Order_Time IS NOT NULL AND Order_Time <> '' THEN 1 ELSE 0 END) AS Invalid_Order_Time,
    SUM(CASE WHEN TRY_CONVERT(date, Delivery_Date) IS NULL
                 AND Delivery_Date IS NOT NULL AND Delivery_Date <> '' THEN 1 ELSE 0 END) AS Invalid_Delivery_Date,
    SUM(CASE WHEN TRY_CONVERT(int, Quantity) IS NULL
                 AND Quantity IS NOT NULL AND Quantity <> '' THEN 1 ELSE 0 END) AS Invalid_Quantity,
    SUM(CASE WHEN TRY_CONVERT(decimal(12,2), Unit_Price) IS NULL
                 AND Unit_Price IS NOT NULL AND Unit_Price <> '' THEN 1 ELSE 0 END) AS Invalid_Unit_Price,
    SUM(CASE WHEN TRY_CONVERT(decimal(14,2), Total_Amount) IS NULL
                 AND Total_Amount IS NOT NULL AND Total_Amount <> '' THEN 1 ELSE 0 END) AS Invalid_Total_Amount
FROM staging_sales;

-- 5. Nietypowe wartości: zamówienia z ujemną wartością
SELECT Order_ID, Order_Date, Coupon_Code, Total_Amount, Order_Status
FROM staging_sales
WHERE TRY_CONVERT(decimal(14,2), Total_Amount) < 0
ORDER BY TRY_CONVERT(decimal(14,2), Total_Amount);

-- 6. Statusy oraz zakres dat
SELECT
    Order_Status,
    COUNT(*) AS Orders,
    SUM(TRY_CONVERT(decimal(14,2), Total_Amount)) AS Total_Amount
FROM staging_sales
GROUP BY Order_Status
ORDER BY Orders DESC;

SELECT
    MIN(TRY_CONVERT(date, Order_Date)) AS First_Order,
    MAX(TRY_CONVERT(date, Order_Date)) AS Last_Order
FROM staging_sales;

-- 7. Sprawdzenie zgodności Quantity * Unit_Price z Order_Value
SELECT COUNT(*) AS Different_Order_Values
FROM staging_sales
WHERE ABS(
    TRY_CONVERT(decimal(14,2), Order_Value)
    - TRY_CONVERT(decimal(14,2), Quantity) * TRY_CONVERT(decimal(14,2), Unit_Price)
) > 0.01;
