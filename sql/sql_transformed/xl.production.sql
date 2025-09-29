CREATE OR ALTER VIEW xl.Production AS
WITH cte AS (
    SELECT 
        --Product Identity
        pr.ProductID, 
        ISNULL(pr.ProductName, '') AS ProductName,
        ISNULL(pr.ProductNumber, '') AS ProductNumber,
        ISNULL(pr.ProductCategory, '') AS Category,
        ISNULL(pr.ProductSubcategory, '') AS SubCategory,
        ISNULL(pr.Color, '') AS Color,
        ISNULL(pr.Size, '') AS Size,

        -- Costs
        CAST(ROUND(ISNULL(pr.StandardCost,0.0), 4) AS decimal(18,4)) AS Standard_Cost,
        CAST(ROUND(ISNULL(pr.ListPrice,0.0),4) AS decimal(18,4)) AS List_Price,

        -- Production Cost
        CAST(ROUND(ISNULL(pr.PlannedProductionCost,0.0), 2) AS decimal(18,2)) AS Planned_Prod_Cost,
        CAST(ROUND(ISNULL(pr.ActualProductionCost,0.0), 2) AS decimal(18,2)) AS Actual_Prod_Cost,
        CAST(ROUND(ISNULL(pr.ActualProductionCost,0.0) - ISNULL(pr.PlannedProductionCost, 0.0),2) AS decimal(18,2)) AS Overhead_Cost,

        -- Margin
        CAST(ROUND(ISNULL(pr.EstimatedMargin,0),0) AS int) AS Estimated_Margin_Value,
        CAST(ROUND(ISNULL(pr.MarginPercent, 0.0), 2) AS decimal(5,2)) AS Margin_Pct,
        CASE WHEN ISNULL(pr.MarginPercent,0) < 65 THEN 'Low' ELSE 'High' END AS Margin_Band,

        -- Inventory (force numeric once here)
        TRY_CAST(pr.CurrentInventory AS decimal(18,2)) AS Current_Inventory,
        TRY_CAST(pr.SafetyStockLevel AS decimal(18,2)) AS Safety_Stock_Level,
        ISNULL(pr.ReorderPoint,0) AS Reorder_Point,	
        ISNULL(pr.InventoryLocation,'') AS Inventory_Location,
        CAST(ROUND(ISNULL(pr.CurrentInventory,0) * ISNULL(pr.StandardCost,0),2) AS decimal(18,2)) AS Inventory_Value,

        -- WorkOrders / BOM
        ISNULL(pr.TotalWorkOrders,0) AS Total_Work_Orders,
        ISNULL(pr.BOM_Count,0) AS BOM_Count,
        ISNULL(pr.QtyPerAssembly,0) AS Qty_Per_Assembly,

        -- Time	
        TRY_CAST(pr.LastWorkOrderDate AS date) AS Last_Work_Order_Date,
        DATEDIFF(DAY, pr.LastWorkOrderDate, GETDATE()) AS Days_Since_Last_WO
    FROM ProductionOverview_curated pr
)
SELECT 
    *,
    CASE 
        WHEN Current_Inventory < Safety_Stock_Level THEN 1 ELSE 0 
    END AS Stockout_Risk_Flag,

    CASE 
        WHEN Current_Inventory > 2 * Safety_Stock_Level THEN 1 ELSE 0 
    END AS Overstock_Flag
FROM cte;
GO
