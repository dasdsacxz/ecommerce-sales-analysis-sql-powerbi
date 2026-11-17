
-- 1. Wartość zamówień i ich liczba według kategorii
SELECT
    p.Category,
    SUM(s.Total_Amount) AS Total_Revenue,
    COUNT(DISTINCT s.Order_ID) AS Orders,
        SUM(s.Total_Amount) / COUNT(DISTINCT s.Order_ID) AS AOV
FROM dbo.Sales s
JOIN dbo.Products p ON p.Product_ID = s.Product_ID
GROUP BY p.Category
ORDER BY Total_Revenue DESC;

-- 2. TOP 10 klientów według wartości zamówień
SELECT TOP (10)
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Tier,
    COUNT(DISTINCT s.Order_ID) AS Orders,
    SUM(s.total_amount) AS laczna_kwota_zakupow
FROM dbo.Customers c
JOIN dbo.Sales s ON s.Customer_ID = c.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name, c.Customer_Tier
ORDER BY laczna_kwota_zakupow DESC;

-- 3. Wartość zamówień według segmentu klienta
SELECT
    c.Customer_Tier,
    COUNT(DISTINCT c.Customer_ID) AS Customers_With_Orders,
    COUNT(DISTINCT s.Order_ID) AS Orders,
    SUM(s.Total_Amount) AS Total_Revenue
FROM dbo.Customers c
JOIN dbo.Sales s ON s.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Tier
ORDER BY Total_Revenue DESC;

-- 4. Podział na statusy zamówień (ważne dla interpretacji "przychodu")
SELECT
    s.Order_Status,
    COUNT(DISTINCT s.Order_ID) AS Orders,
    SUM(s.Total_Amount) AS Total_Revenue
FROM dbo.Sales s
GROUP BY s.Order_Status
ORDER BY Total_Revenue DESC;

-- 5. Częstość wykorzystania poszczególnych kuponów
SELECT
    CASE
        WHEN s.Coupon_Code IS NULL OR LTRIM(RTRIM(s.Coupon_Code)) = ''
            THEN '(bez kuponu)'
        ELSE s.Coupon_Code
    END AS Coupon,
    COUNT(DISTINCT s.Order_ID) AS Orders,
    SUM(s.Total_Amount) AS Total_Revenue,
        SUM(s.Total_Amount)
        / NULLIF(COUNT(DISTINCT s.Order_ID), 0)AS AOV
FROM dbo.Sales s
GROUP BY CASE
    WHEN s.Coupon_Code IS NULL OR LTRIM(RTRIM(s.Coupon_Code)) = ''
        THEN '(bez kuponu)'
    ELSE s.Coupon_Code
END
ORDER BY Orders DESC;

-- 6. Ranking klientów wewnątrz stanów (funkcja okienkowa RANK)
WITH ranking AS (
SELECT c.customer_id,
c.customer_name,
SUM(s.total_amount) AS suma_wydatkow,
c.state,
RANK() OVER (PARTITION BY c.state ORDER BY SUM(total_amount) DESC) AS ranking
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name, c.state)
SELECT customer_id, customer_name, suma_wydatkow, ranking, state
FROM ranking

-- 7. Data pierwszego zamówienia klienta - liczba klientów według miesiąca
--    To data pierwszego zamówienia W OBRĘBIE danych, nie pewny początek relacji.
SELECT MONTH(pierwsza_data) AS miesiac, YEAR(pierwsza_data) AS rok, COUNT(customer_id) AS nowi_klienci
FROM (
    SELECT customer_id, MIN(order_date) AS pierwsza_data
    FROM sales
    GROUP BY customer_id
) AS pierwsze_zamowienia
GROUP BY MONTH(pierwsza_data), YEAR(pierwsza_data)
ORDER BY rok, miesiac

--8. MoM Growth - Zmiana procentowa przychodu miesiąc do miesiąca

WITH przychodmiesieczny AS (
SELECT DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS miesiac, SUM(total_amount) AS przychod
FROM sales
GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)),
zmianaprzychodu AS (
SELECT miesiac, przychod,
LAG(przychod) OVER (ORDER BY miesiac) AS poprzednimiesiac,
(przychod - LAG(przychod) OVER (ORDER BY miesiac)) * 100.0 / NULLIF(LAG(przychod) OVER (ORDER BY miesiac), 0) AS zmianaprocentowa
FROM przychodmiesieczny)
SELECT miesiac, przychod, zmianaprocentowa
FROM zmianaprzychodu

-- 9. Średnia ocena produktów od najniższej do najwyższej
WITH sredniaocena AS (
SELECT p.product_id, p.product_name, AVG(s.rating) AS srednia_ocena, p.category
FROM products p 
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, p.category
)
SELECT so.product_id, so.product_name, so.srednia_ocena
FROM sredniaocena so
WHERE so.srednia_ocena < (
    SELECT AVG(so2.srednia_ocena)
    FROM sredniaocena so2
    WHERE so2.category = so.category 
)
ORDER BY so.srednia_ocena;