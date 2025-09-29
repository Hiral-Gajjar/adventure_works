CREATE OR ALTER VIEW xl.SalesOverview AS

SELECT 
    -- Keys and dates
    so.SalesOrderID  AS Sales_Order_ID,
    CAST(so.OrderDate AS date) AS Order_Date, 
    YEAR(so.OrderDate) AS Order_Year,
    MONTH(so.OrderDate) AS Order_Month,
    DATEPART(QUARTER, so.OrderDate) AS Order_Quarter,

    -- Customer info 
    so.CustomerID AS Customer_ID, 
    ISNULL(so.CustomerAccountNumber, '') AS Customer_Account, 
    ISNULL(so.StoreName, '') AS Store_Name,

    -- Money and Quantity
    ISNULL(so.TotalOrderQty,0) AS Total_Qty, 
    CAST(ROUND(ISNULL(so.TotalOrderValue,0.0),2) AS decimal(28,2)) AS Order_Value,
    CAST(
        ROUND(
            CASE WHEN so.TotalOrderQty=0 THEN NULL
                 ELSE 1.0*so.TotalOrderValue/NULLIF(so.TotalOrderQty,0) END, 
        4) AS decimal(28,4)) AS Unit_Price,

    -- Payment info
    ISNULL(so.CardType, '') AS Card_Type,

    -- Currency info
    ISNULL(so.ToCurrencyCode, '') AS To_Currency,
    ISNULL(so.FromCurrencyCode, '') AS From_Currency,
    CAST(ISNULL(so.AverageRate,0.0) AS decimal(28,6)) AS Fx_Avg_Rate,
        
    -- Taxes and Discounts
    CAST(ISNULL(so.DiscountPct,0.0) AS decimal(9,4)) AS Discount_Pct,
    CAST(ISNULL(so.TaxRate,0.0) AS decimal(9,4)) AS Tax_Rate_Pct,
    ISNULL(so.SalesTaxName, '')  AS Sales_Tax_Name,

    CAST(
        ROUND(
            ISNULL(so.TaxRate, 0.0) * ISNULL(so.TotalOrderValue, 0.0) / 100.0, 
        2) AS decimal(28,2)) AS Tax_Paid,

    -- Sales performance
    CAST(ISNULL(so.SalesQuota,0.0) AS decimal(28,6)) AS Sales_Quota,
    CAST(ISNULL(so.SalesYTD,0.0) AS decimal(28,6)) AS Sales_YTD,
    CAST(ISNULL(so.CommissionPct,0.0) AS decimal(9,4)) AS Commission_Pct,

    -- Sales Reasons
    ISNULL(so.SalesReasonName, '') AS Sales_Reason

FROM dbo.SalesOverview_backup so;
