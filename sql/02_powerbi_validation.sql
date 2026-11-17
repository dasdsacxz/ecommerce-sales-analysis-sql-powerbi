/*
    02_powerbi_validation.sql
    walidacja miar Power BI
    Ten sam okres, wszystkie statusy zamówień, brak innych filtrów.
    Logika bazuje na stronie 5 załączonego raportu portfolio.
*/

-- 1. KPI dla pełnego okresu
SELECT
    SUM(Total_Amount) AS Revenue_All_Statuses,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Customers_With_Orders,
        SUM(Total_Amount)
        / NULLIF(COUNT(DISTINCT Order_ID), 0) AS AOV
FROM dbo.Sales;

-- Oczekiwane wg raportu PDF (25 miesięcy, wszystkie statusy):
-- Revenue_All_Statuses: 5 930 693 254,30
-- Total_Orders:         250 000
-- Customers_With_Orders: 39 914
-- AOV:                   23 722,77

-- 2. Rozbicie statusu Delivered
SELECT
    COUNT(DISTINCT Order_ID) AS Delivered_Orders,
    SUM(Total_Amount) AS Delivered_Total_Amount
FROM dbo.Sales
WHERE Order_Status = 'Delivered';

-- 3. Miesięczny przychód oraz MoM
WITH MonthlyRevenue AS (
    SELECT
        DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1) AS Month_Start,
        SUM(Total_Amount) AS Revenue
    FROM dbo.Sales
    GROUP BY DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)
), PreviousMonth AS (
    SELECT
        Month_Start,
        Revenue,
        LAG(Month_Start) OVER (ORDER BY Month_Start) AS Previous_Month_Start,
        LAG(Revenue) OVER (ORDER BY Month_Start) AS Previous_Revenue
    FROM MonthlyRevenue
)
SELECT
    Month_Start,
    Revenue,
    Previous_Revenue,
    CASE WHEN DATEDIFF(month, Previous_Month_Start, Month_Start) = 1
         THEN 100.0 * (Revenue - Previous_Revenue)
              / NULLIF(Previous_Revenue, 0)
    END AS MoM_Percent
FROM PreviousMonth
ORDER BY Month_Start;

-- Wg raportu: maj 2026 235 484 942,44; czerwiec 235 684 585,33.
-- Zaokrąglony MoM czerwca 2026: +0,08%.

-- 4. Miesięczne zamówienia i AOV (pomocne do interpretacji trendów)
SELECT
    DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1) AS Month_Start,
    COUNT(DISTINCT Order_ID) AS Orders,
    SUM(Total_Amount) AS Revenue,
        SUM(Total_Amount)
        / NULLIF(COUNT(DISTINCT Order_ID), 0) AS AOV
FROM dbo.Sales
GROUP BY DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)
ORDER BY Month_Start;
