CREATE OR ALTER VIEW xl.Purchasing AS 

SELECT
	--Keys
	pa.ProductID AS ProductID, 
	pa.PurchaseOrderID AS PO_ID , 
	pa.PurchaseOrderDetailID AS PO_Detail_ID, 

	--Vendor
	ISNULL(pa.VendorName, '') AS Vendor_Name, 
	ISNULL(pa.VendorAccountNumber, '') AS Vendor_Account,
	ISNULL(pa.ShipMethodName, '') AS Ship_Method,

	--Dates
	TRY_CAST(pa.OrderDate AS date) AS Order_Date, 
	TRY_CAST(pa.ShipDate AS date) AS Ship_Date,
	TRY_CAST(pa.OrderDueDate AS date) AS Due_Date,
	TRY_CAST(pa.LastReceiptDate AS date) AS Last_Receipt_Date,
	YEAR(pa.OrderDate) AS Order_Year,
	MONTH(pa.OrderDate) AS Order_Month,

	--Qty/Price
	ISNULL(pa.PurchaseOrderQuantity, 0) AS Ordered_Qty,
	ISNULL(pa.ReceivedQty,0) AS Received_Qty, 
	ISNULL(pa.RejectedQty,0) AS Rejected_Qty,
	CAST(ROUND(ISNULL(pa.ProductUnitPrice,0.0),4) AS decimal(18,4)) AS Unit_Price,
	CAST(ROUND(ISNULL(pa.StandardPrice,0.0),4) AS decimal(18,4)) AS Standard_Price,
	CAST(ROUND(ISNULL(pa.TotalOrderPrice,0.0),2) AS decimal(18,2)) AS Line_Total,
	CAST(ROUND(ISNULL(pa.TotalAmtDue,0.0),2) AS decimal(18,2)) AS Amount_Due,
	

	--Freight
	CAST(ROUND(ISNULL(pa.Freight, 0.0),2) AS decimal(18,2)) AS Freight,
	CAST(ROUND(ISNULL(pa.TaxAmt, 0.0), 2) AS decimal(18,2)) AS Tax_Amt,

	--Calculated Helpers
	CAST(1.0 * ISNULL(pa.StockedQty,0) / NULLIF(ISNULL(pa.PurchaseOrderQuantity,0),0) AS decimal(18,4)) AS Fulfillment_Rate,
	CAST(1.0 * ISNULL(pa.RejectedQty,0) / NULLIF(ISNULL(pa.ReceivedQty,0),0) AS decimal(18,4)) AS Rejection_Rate,
	DATEDIFF(DAY, pa.OrderDate, pa.ShipDate) AS Actual_Lead_Time,
	CAST(CASE WHEN pa.ShipDate <= pa.OrderDueDate THEN 1 ELSE 0 END AS bit) AS On_Time_Flag,

	--Data Quality flags
	CASE 
		WHEN pa.ShipDate < pa.OrderDate OR  pa.LastReceiptDate < pa.OrderDate OR pa.OrderDueDate < pa.OrderDate
			THEN 'Bad_ReceiptDate'
		ELSE 'OK'
	END AS Data_Quality

FROM Purchasing_analysis pa;
GO