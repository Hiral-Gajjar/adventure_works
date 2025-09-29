SELECT * FROM [Purchasing].[ProductVendor] --460
SELECT * FROM [Purchasing].[PurchaseOrderDetail] -- 8845
SELECT * FROM [Purchasing].[PurchaseOrderHeader] -- 4012
SELECT * FROM [Purchasing].[ShipMethod] -- 5
SELECT * FROM [Purchasing].[Vendor] -- 104


SELECT 
pv.ProductID AS ProductID, 
pv.BusinessEntityID AS BusinessEntityID, 
pv.AverageLeadTime AS AverageLeadTime, 
pv.StandardPrice AS StandardPrice, 
pv.LastReceiptCost AS LastReceiptCost, 
pv.LastReceiptDate AS LastReceiptDate,
pv.MinOrderQty AS MinOrderQty, 
pv.MaxOrderQty AS MaxOrderQty, 
pv.OnOrderQty AS OnOrderQty, 
pv.UnitMeasureCode AS UnitMeasureCode,

pod.PurchaseOrderID AS PurchaseOrderID, 
pod.PurchaseOrderDetailID AS PurchaseOrderDetailID, 
pod.DueDate AS OrderDueDate, 
pod.OrderQty AS PurchaseOrderQuantity, 
pod.UnitPrice AS ProductUnitPrice, 
pod.LineTotal AS TotalOrderPrice, 
pod.ReceivedQty AS ReceivedQty,
pod.RejectedQty AS RejectedQty, 
pod.StockedQty AS StockedQty,

poh.RevisionNumber AS RevisionNumber, 
poh.Status AS Status, 
poh.EmployeeID AS EmployeeID, 
poh.ShipMethodID AS ShipMethodID, 
poh.OrderDate AS OrderDate, 
poh.ShipDate AS ShipDate, 
poh.SubTotal AS SubTotal, 
poh.TaxAmt AS TaxAmt,
poh.Freight AS Freight, 
poh.TotalDue AS TotalAmtDue,

sm.Name AS ShipMethodName, 
SM.ShipBase AS ShipBaseCost, 
sm.ShipRate AS ShipRatePerUnit,

v.AccountNumber AS VendorAcNumber, 
v.Name AS VendorName, 
v.CreditRating AS CreditRating, 
v.PreferredVendorStatus AS PreferredVendorStatus, 
v.ActiveFlag AS ActiveFlag, 
v.PurchasingWebServiceURL AS PurchasingWebServiceURL

INTO PurchasingSummary

FROM [Purchasing].[PurchaseOrderHeader] poh
JOIN [Purchasing].[PurchaseOrderDetail] pod 
	ON poh.PurchaseOrderID = pod.PurchaseOrderID
JOIN [Purchasing].[ShipMethod] sm
	ON poh.ShipMethodID = sm.ShipMethodID
JOIN [Purchasing].[Vendor] v
	ON poh.VendorID = v.BusinessEntityID
JOIN [Purchasing].[ProductVendor] pv
	ON pod.ProductID = pv.ProductID
	AND v.BusinessEntityID = pv.BusinessEntityID

WITH RankedPurchases AS (
		SELECT *, 
			ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY OrderDate DESC) AS rn
		FROM [dbo].[PurchasingSummary]
)

SELECT *,
CASE 
--updated OnOrderQty column based on OnOrderQty Max Occuring Qty
	WHEN OnOrderQty IS NULL AND MinOrderQty = 100 AND MaxOrderQty = 1000 THEN 300
	WHEN OnOrderQty IS NULL AND MinOrderQty = 1 AND MaxOrderQty = 5 THEN 3
	WHEN OnOrderQty IS NULL AND MinOrderQty = 20 AND MaxOrderQty = 100 THEN 60
	WHEN OnOrderQty IS NULL AND MinOrderQty = 500 AND MaxOrderQty = 2000 THEN 1500
	ELSE OnOrderQty
	END AS FilledOnOrderQty
FROM RankedPurchases
WHERE rn = 1
INTO PurchasingSummary_backup
 AND OnOrderQty IS NULL