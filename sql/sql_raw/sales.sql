SELECT * FROM [Sales].[CountryRegionCurrency] --109
SELECT * FROM [Sales].[CreditCard] --19118
SELECT * FROM [Sales].[Currency] --105
SELECT * FROM [Sales].[CurrencyRate] --13532
SELECT * FROM [Sales].[Customer] --19820
SELECT * FROM [Sales].[PersonCreditCard] --19118
SELECT * FROM [Sales].[SalesOrderDetail]  --121317
SELECT * FROM [Sales].[SalesOrderHeader] --31465
SELECT * FROM [Sales].[SalesOrderHeaderSalesReason] --27647
SELECT * FROM [Sales].[SalesPerson] --17
SELECT * FROM [Sales].[SalesPersonQuotaHistory] --163
SELECT * FROM [Sales].[SalesReason] --10
SELECT * FROM [Sales].[SalesTaxRate] --29
SELECT * FROM [Sales].[SalesTerritory] --10
SELECT * FROM [Sales].[SalesTerritoryHistory] --17
SELECT * FROM [Sales].[ShoppingCartItem] --3
SELECT * FROM [Sales].[SpecialOffer] --16
SELECT * FROM [Sales].[SpecialOfferProduct] --538
SELECT * FROM [Sales].[Store] --701



WITH CustomerInfo AS (
	SELECT 
		CustomerID, PersonID, StoreID, TerritoryID, AccountNumber AS CustomerAccountNumber
	FROM [Sales].[Customer]
),

SalesOrders AS (
	SELECT * FROM [Sales].[SalesOrderHeader]
),

OrderDetails AS (
	SELECT 
		SalesOrderID, SalesOrderDetailID ,CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, 
		UnitPrice, LineTotal AS TotalSalePrice
	FROM [Sales].[SalesOrderDetail]
),

CreditCardInfo AS (
	SELECT 
		CreditCardID, CardType, CardNumber, ExpMonth, ExpYear
	FROM [Sales].[CreditCard]
),

CurrencyDetails AS (
	SELECT 
		CurrencyRateID, CurrencyRateDate, FromCurrencyCode, ToCurrencyCode, AverageRate, EndOfDayRate
	FROM [Sales].[CurrencyRate]
),

SalesPersonInfo AS (
	SELECT
		BusinessEntityID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear
	FROM [Sales].[SalesPerson]
),

SalesReasonInfo AS (
	SELECT sr.SalesReasonID, sr.Name AS SalesReasonName, sr.ReasonType AS SalesReasonType,
		sohsr.SalesOrderID AS SalesOrderID
	FROM [Sales].[SalesReason] sr 
	JOIN [Sales].[SalesOrderHeaderSalesReason] sohsr ON sr.SalesReasonID = sohsr.SalesReasonID
), 

TaxRegionInfo AS (
	SELECT strate.SalesTaxRateID, strate.StateProvinceID, strate.TaxType, strate.TaxRate,  
		strate.Name AS SalesTaxName, addr.AddressID, addr.StateProvinceID AS AddrStateProvinceID, 
		prv.StateProvinceID AS ProvinceID
	FROM [Person].[Address] addr
	JOIN [Person].[StateProvince] prv ON addr.StateProvinceID = prv.StateProvinceID
	JOIN [Sales].[SalesTaxRate] strate ON prv.StateProvinceID = strate.StateProvinceID
),

ShoppingCartInfo AS (
	SELECT 
		ShoppingCartItemID, ShoppingCartID, ProductID, Quantity, DateCreated
	FROM [Sales].[ShoppingCartItem]
),

SpecialOfferInfo AS (
	SELECT 
		SpecialOfferID, Description, DiscountPct, Type, Category, StartDate, EndDate, MinQty, MaxQty
	FROM [Sales].[SpecialOffer]
),

StoreInfo AS (
	SELECT 
		BusinessEntityID, Name AS StoreName, Demographics, SalesPersonID
	FROM [Sales].[Store]
), 

RankedSales AS (
SELECT 
--Sales Order Details
	so.SalesOrderID, so.OrderDate, so.DueDate, so.ShipDate, so.TotalDue,

--Customer
	c.CustomerAccountNumber, c.CustomerID,

--Order Details
	od.OrderQty, od.TotalSalePrice,

--Credit card
	cc.CardType, 

--Currency
	cd.AverageRate,cd.ToCurrencyCode, cd.FromCurrencyCode,

--Sales Person
	sp.SalesQuota, sp.Bonus, sp.CommissionPct, sp.SalesYTD, sp.SalesLastYear,

--Sales Reason
	sr.SalesReasonName,

--Tax & Region
	tr.TaxRate, tr.SalesTaxName, tr.TaxType,

--Shopping Cart
	sc.Quantity AS CartQty,
	sc.DateCreated AS CartCreatedDate,

--Special Offer
	soffer.DiscountPct,

--Store
	strinfo.StoreName,

	ROW_NUMBER() OVER(
		PARTITION BY so.SalesOrderID, od.ProductID, od.OrderQty, od.TotalSalePrice,	c.CustomerID
		ORDER BY so.SalesOrderID	
	) AS rn

FROM SalesOrders so
LEFT JOIN CustomerInfo c ON so.CustomerID = c.CustomerID
LEFT JOIN OrderDetails od ON so.SalesOrderID = od.SalesOrderID
LEFT JOIN CreditCardInfo cc ON so.CreditCardID = cc.CreditCardID
LEFT JOIN CurrencyDetails cd ON so.CurrencyRateID = cd.CurrencyRateID
LEFT JOIN SalesPersonInfo sp ON so.SalesPersonID = sp.BusinessEntityID
LEFT JOIN SalesReasonInfo sr ON so.SalesOrderID = sr.SalesOrderID
LEFT JOIN TaxRegionInfo tr ON so.ShipToAddressID = tr.AddressID
LEFT JOIN ShoppingCartInfo sc ON od.ProductID = sc.ProductID
LEFT JOIN SpecialOfferInfo soffer ON od.SpecialOfferID = soffer.SpecialOfferID
LEFT JOIN StoreInfo strinfo ON so.SalesPersonID = strinfo.SalesPersonID
)

SELECT 
	SalesOrderID, 
	MAX(OrderDate) AS OrderDate, 
	MAX(DueDate) AS DueDate,
    MAX(ShipDate) AS ShipDate,
    SUM(CAST(OrderQty AS int)) AS TotalOrderQty,
    SUM(CAST(TotalSalePrice AS decimal(19,4))) AS TotalOrderValue,
    MAX(CustomerAccountNumber) AS CustomerAccountNumber,
    MAX(CustomerID) AS CustomerID,
    MAX(CardType) AS CardType,
	 MAX(ToCurrencyCode) AS ToCurrencyCode,
    MAX(FromCurrencyCode) AS FromCurrencyCode,
    MAX(CAST(AverageRate AS decimal(18,8))) AS AverageRate,
	MAX(CAST(DiscountPct AS decimal(7,4))) AS DiscountPct,
	MAX(CAST(TaxRate AS decimal(7,4))) AS TaxRate,
	MAX(SalesTaxName) AS SalesTaxName,
	MAX(TaxType) AS TaxType,
    MAX(SalesQuota) AS SalesQuota,
    MAX(Bonus) AS Bonus,
    MAX(CommissionPct) AS CommissionPct,
    MAX(SalesYTD) AS SalesYTD,
    MAX(SalesLastYear) AS SalesLastYear,
    MAX(SalesReasonName) AS SalesReasonName,     
    MAX(StoreName) AS StoreName
INTO SalesOverview
FROM RankedSales
WHERE rn = 1
GROUP BY SalesOrderID;

