SELECT * FROM [Production].[BillOfMaterials] -- 2679
SELECT * FROM [Production].[Culture] --8 rows
SELECT * FROM [Production].[Document] -- 13
SELECT * FROM [Production].[Illustration] --5
SELECT * FROM [Production].[Location] --14
SELECT * FROM [Production].[Product] -- 504
SELECT * FROM [Production].[ProductCategory] --4
SELECT * FROM [Production].[ProductCostHistory] -- 395
SELECT * FROM [Production].[ProductDescription] -- 762
SELECT * FROM [Production].[ProductDocument] -- 32
SELECT * FROM [Production].[ProductInventory] --1069
SELECT * FROM [Production].[ProductListPriceHistory] -- 395
SELECT * FROM [Production].[ProductModel] --128
SELECT * FROM [Production].[ProductModelIllustration] --7
SELECT * FROM [Production].[ProductModelProductDescriptionCulture] --762
SELECT * FROM [Production].[ProductPhoto]  -- 101
SELECT * FROM [Production].[ProductProductPhoto] -- 504
SELECT * FROM [Production].[ProductReview] -- 4
SELECT * FROM [Production].[ProductSubcategory] -- 37
SELECT * FROM [Production].[ScrapReason] --16
SELECT * FROM [Production].[TransactionHistory] -- 113443
SELECT * FROM [Production].[TransactionHistoryArchive] -- 89253
SELECT * FROM [Production].[UnitMeasure] -- 38
SELECT * FROM [Production].[WorkOrder] -- 72591
SELECT * FROM [Production].[WorkOrderRouting] -- 67131


WITH Productinfo AS (
	SELECT * FROM [Production].[Product]
),

ProductCost AS (
	SELECT 
		ProductID, StartDate AS ProductStartDate, EndDate AS ProductEndDate, StandardCost AS ProductStdCost 
		FROM (SELECT *,
		ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY EndDate DESC)  AS cost_row
	FROM [Production].[ProductCostHistory] ) cost
	WHERE cost_row = 1
),

ProductDocument AS (
	SELECT 
		ProductID, DocumentNode
		FROM (
			SELECT *, ROW_NUMBER() OVER(PARTITION BY ProductID order by ProductID) AS document_row
			FROM [Production].[ProductDocument]
	)doc
	WHERE document_row = 1
),

ProductInventory AS (
	SELECT 
		ProductID, LocationID, Shelf, Bin, Quantity 
	FROM (
		SELECT *, ROW_NUMBER() 	OVER(PARTITION BY ProductID ORDER BY ProductID) AS inventory_row
	FROM [Production].[ProductInventory]
	) inv 
	WHERE inventory_row = 1
	
),

ProductListPrice AS (
	SELECT 
		ProductID, ListPrice, StartDate, EndDate 
	FROM (
		SELECT *, ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY EndDate DESC) AS listprice_row
		FROM [Production].[ProductListPriceHistory])
	list 
	WHERE listprice_row = 1
	
),

ProductModel AS (
	SELECT
		pm.ProductModelID, Name AS ProductModelName, Catalogdescription, Instructions, IllustrationID, ProductDescriptionID, CultureID
	FROM [Production].[ProductModel] pm
	LEFT JOIN [Production].[ProductModelIllustration] pmi ON pm.ProductModelID = pmi.ProductModelID
	LEFT JOIN [Production].[ProductModelProductDescriptionCulture] pmpd ON pm.ProductModelID = pmpd.ProductModelID
),

ProductPhoto AS (
	SELECT
		photo.ProductPhotoID, ThumbNailPhoto, ThumbnailPhotoFileName, LargePhoto, LargePhotoFileName,
		prphoto.ProductID, prphoto.[Primary], preview.ProductReviewID, ReviewerName, ReviewDate, EmailAddress, rating, Comments,
		ROW_NUMBER() OVER(PARTITION BY prphoto.ProductID  ORDER BY photo.ProductPhotoID) AS pphoto_row
	FROM [Production].[ProductProductPhoto] prphoto  
	LEFT JOIN [Production].[ProductReview] preview ON prphoto.ProductID = preview.ProductID
	LEFT JOIN [Production].[ProductPhoto] photo ON photo.ProductPhotoID = prphoto.ProductPhotoID
	WHERE prphoto.ProductID IS NOT NULL 
),

ProductCategoryDetails AS (
	SELECT 
		DISTINCT ProductSubCategoryID, pscgry.ProductCategoryID, pcgry.Name AS CategoryName, pscgry.Name as SubcategoryName
	FROM [Production].[ProductSubcategory] pscgry
	LEFT JOIN [Production].[ProductCategory] pcgry ON pscgry.ProductCategoryID = pcgry.ProductCategoryID
),

ScrapReason AS (
	SELECT 
		ScrapReasonID, Name AS ScrapreasonName
	FROM [Production].[ScrapReason]
),

TransactionDetails AS (
	SELECT 
		thist.TransactionID, thist.ProductID, thist.ReferenceOrderID, thist.ReferenceOrderLineID, thist.TransactionDate, 
		thist.TransactionType, thist.Quantity, thist.ActualCost,
		 ROW_NUMBER() OVER(PARTITION BY thist.ProductID ORDER BY thist.TransactionDate DESC) AS thist_row
			FROM [Production].[TransactionHistory] thist
			JOIN [Production].[TransactionHistoryArchive] thistarch ON thist.ProductID = thistarch.ProductID 
			WHERE thist.ProductID IS NOT NULL
),

FinalTransaction AS (
	SELECT * FROM TransactionDetails WHERE thist_row = 1
),

UnitMeasure AS (
	SELECT
		UnitMeasureCode, Name AS UnitName
	FROM [Production].[UnitMeasure]
),

WorkOrderDetails AS (
	SELECT 
		wo.WorkOrderID, wo.ProductID, OrderQty, StockedQty, ScrappedQty, StartDate, EndDate, DueDate, ScrapReasonID,
		OperationSequence,	LocationID, ScheduledStartDate, ScheduledEndDate, ActualStartDate, ActualEndDate, ActualResourceHrs, PlannedCost, ActualCost, 	
		ROW_NUMBER() OVER(PARTITION BY wo.ProductID ORDER BY ScheduledStartDate) AS wo_row
	FROM [Production].[WorkOrder] wo
	LEFT JOIN [Production].[WorkOrderRouting] wor ON wo.WorkOrderID = wor.WorkOrderID
	AND wo.ProductID = wor.ProductID
	WHERE wo.ProductID IS NOT NULL
),

BillOfMaterial AS (
	SELECT 
		BillOfMaterialsID, ProductAssemblyID, ComponentID, StartDate, EndDate, UnitMeasureCode, BOMLevel, PerAssemblyQty 
		FROM (
		SELECT *, ROW_NUMBER() OVER(PARTITION BY BillOfMaterialsID ORDER BY BillOfMaterialsID) AS bom_row
	FROM [Production].[BillOfMaterials]) material
	WHERE bom_row = 1
),

Culture AS (
	SELECT 
		CultureID, Name AS CultureName
	FROM [Production].[Culture]
),

Document AS (
	SELECT 
		DocumentNode, DocumentLevel, Title, Owner, FolderFlag, FileName, FileExtension, Revision, ChangeNumber, Status, DocumentSummary, Document
	FROM [Production].[Document]
), 

Illustration AS (
	SELECT 
		IllustrationID, Diagram
	FROM [Production].[Illustration]
),

[Location] AS (
	SELECT 
		LocationID, Name AS LocationName, CostRate, Availability
	FROM [Production].[Location]
),

ProductDescription AS (
	SELECT 
		ProductDescriptionID, Description
	FROM [Production].[ProductDescription]
),


FinalProduction AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY ProductID ORDER BY ReviewDate DESC) AS rn
	FROM (

SELECT 
--product
p.ProductID, 
p.Name AS ProductName, 
p.ProductNumber, 
p.MakeFlag, 
p.FinishedGoodsFlag, 
p.Color, 
p.SafetyStockLevel, 
p.ReorderPoint, 
p.StandardCost AS CurrentStandardCost,
p.ListPrice AS StaticListPrice, 
p.Size, 
p.SizeUnitMeasureCode, 
p.WeightUnitMeasureCode,
p.Weight, 
p.DaysToManufacture, 
p.ProductLine, 
p.Class, 
p.style, 
p.SellStartDate, 
p.SellEndDate, 
p.DiscontinuedDate,

--Product document
pdoc.DocumentNode,

--product Inventory
pinv.LocationID AS InventoryLocation, 
pinv.Shelf, 
pinv.Bin, 
pinv.Quantity AS InventoryQty,

--Product List price 
listpr.StartDate AS ProductListStartDate, 
listpr.EndDate AS ProductListEndPrice,

--Product Model 
pm.ProductModelName, 

--Product Photo
pp.[Primary], 
pp.ProductReviewID,
pp.ReviewerName, 
pp.ReviewDate, 
pp.EmailAddress, 
pp.Rating, 

--Transaction Details 
tdeats.TransactionDate, 
tdeats.Quantity AS TranscationQty, 
tdeats.ActualCost,

--UnitMeasure
um.UnitMeasureCode, 
um.UnitName,

--WorkOrderDetails
wod.WorkOrderID, 
wod.OrderQty, 
wod.StockedQty, 
wod.ScrappedQty, 
wod.StartDate AS WorkOrderStartDate, 
wod.EndDate AS WorkOrderEndDate,
wod.DueDate AS WorkOrderDueDate, 
wod.ScrapReasonID, 
wod.OperationSequence,
wod.LocationID AS WorkOrderLocationID, 
wod.ScheduledStartDate, 
wod.ScheduledEndDate,
wod.ActualStartDate,
wod.ActualEndDate, 
wod.PlannedCost, 
wod.ActualCost AS WorkOrderActualCost,

--BillOfMaterial
bom.BillOfMaterialsID, 
bom.ProductAssemblyID, 
bom.ComponentID,
bom.StartDate AS BillOfMaterialStartDate, 
bom.EndDate AS BillOfMaterialEndDate,
bom.BOMLevel, 
bom.PerAssemblyQty,

--Culture
cltre.CultureID AS CultureID, 
cltre.CultureName,

--Document
doc.DocumentLevel, 
doc.title AS DocumentTitle,
doc.Owner AS DocumentOwner, 
doc.FolderFlag, 
doc.FileName, 
doc.FileExtension, 
doc.Revision, 
doc.ChangeNumber, 
doc.Status, 
doc.DocumentSummary,
doc.Document, 

--Illustration
il.IllustrationID, 
il.Diagram, 

--Location
loc.LocationID AS MasterLocationID, 
loc.LocationName, 
loc.CostRate, 
loc.Availability, 

--ProductCategoryDetails
pcd.ProductCategoryID, 
pcd.CategoryName, 
pcd.ProductSubcategoryID, 
pcd.SubcategoryName,

--ProductDescription
pdsc.ProductDescriptionID, 
pdsc.Description


FROM Productinfo AS p 
LEFT JOIN ProductCost pc ON p.ProductID = pc.ProductID
LEFT JOIN ProductDocument pdoc ON p.ProductID = pdoc.ProductID
LEFT JOIN ProductInventory pinv ON p.ProductID = pinv.ProductID
LEFT JOIN ProductListPrice listpr ON p.ProductID = listpr.ProductID
LEFT JOIN ProductModel pm ON P.ProductModelID = pm.ProductModelID
LEFT JOIN ProductPhoto pp ON p.ProductID = pp.ProductID
LEFT JOIN FinalTransaction tdeats ON p.ProductID = tdeats.ProductID
LEFT JOIN UnitMeasure um ON p.SizeUnitMeasureCode = um.UnitMeasureCode
LEFT JOIN WorkOrderDetails wod ON p.ProductID = wod.ProductID
LEFT JOIN BillOfMaterial bom ON p.ProductID = bom.ProductAssemblyID
LEFT JOIN Culture cltre ON pm.CultureID = cltre.CultureID
LEFT JOIN Document doc ON pdoc.DocumentNode = doc.DocumentNode
LEFT JOIN Illustration il ON pm.IllustrationID = il.IllustrationID
LEFT JOIN [Location] loc ON pinv.LocationID = loc.LocationID
LEFT JOIN ProductCategoryDetails pcd ON p.ProductSubcategoryID = pcd.ProductSubcategoryID
LEFT JOIN ProductDescription pdsc ON pm.ProductDescriptionID = pdsc.ProductDescriptionID
) AS full_data
)


SELECT 
    ProductID,

    -- Basic product info
    MAX(ProductName) AS ProductName,
    MAX(ProductNumber) AS ProductNumber,
    MAX(Color) AS Color,
    MAX(Size) AS Size,
    MAX(Weight) AS Weight,
    MAX(CategoryName) AS ProductCategory,
    MAX(SubcategoryName) AS ProductSubcategory,

    -- Costing & Pricing
    MAX(CurrentStandardCost) AS StandardCost,
    MAX(StaticListPrice) AS ListPrice,
    MAX(PlannedCost) AS PlannedProductionCost,
    MAX(WorkOrderActualCost) AS ActualProductionCost,

    -- Inventory & Stock Status
    MAX(SafetyStockLevel) AS SafetyStockLevel,
    MAX(ReorderPoint) AS ReorderPoint,
    MAX(InventoryQty) AS CurrentInventory,
    MAX(LocationName) AS InventoryLocation,

    -- Production Structure (BOM)
    COUNT(DISTINCT BillOfMaterialsID) AS BOM_Count,
    MAX(PerAssemblyQty) AS QtyPerAssembly,

    -- Manufacturing Metrics
    COUNT(DISTINCT WorkOrderID) AS TotalWorkOrders,
    MAX(WorkOrderStartDate) AS LastWorkOrderDate,

    --  Customer Feedback
    MAX(Rating) AS LastRating,
    MAX(ReviewerName) AS Reviewer,
    MAX(ReviewDate) AS LastReviewDate,

    --  Profitability Metrics
    MAX(StaticListPrice) - MAX(CurrentStandardCost) AS EstimatedMargin,
    (MAX(StaticListPrice) - MAX(CurrentStandardCost)) * 100.0 
        / NULLIF(MAX(CurrentStandardCost), 0) AS MarginPercent

INTO ProductionOverview
FROM FinalProduction
WHERE rn = 1
GROUP BY ProductID;















