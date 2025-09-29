CREATE OR ALTER VIEW xl.CustomerInfo AS

SELECT 
	--IDs/Keys
	ci.AddressID AS AddressID, 
	ci.TerritoryID AS TerritoryID,

	--Location
	ISNULL(ci.CountryName, '') AS Country_Region_Code,
	ISNULL(ci.CountryRegionCode, '') AS Country_Code,
	ISNULL(ci.ProvinceName, '') AS ProvinceName,
	ISNULL(ci.City, '') AS City,
	ISNULL(ci.PostalCode, '') AS Postal_Code,
	
	--Person
	ISNULL(ci.AddressName, '') AS Address_Name, 
	ISNULL(ci.ContactName, '') AS Contact_Name, 
	ISNULL(ci.FullName, '') AS Full_Name, 
	ISNULL(ci.EmailAddress, '') AS Email, 
	ISNULL(ci.PhoneNumber, '') AS Phone,
	ISNULL(ci.PhoneType, '') AS Phone_Type,
	ISNULL(ci.PersonType, '') AS Person_Type,		
	CAST(CASE WHEN ci.EmailAddress IS NULL THEN 0 ELSE 1 END AS bit) AS Has_Email,

	--Demographics
	ISNULL(ci.Educationlevel, 'Unknown') AS Education_Level,
	ISNULL(ci.MaritalStatus, 'Unknown') AS Marital_Status,
	CASE 
		WHEN ci.HomeOwnerFlag = 1 THEN 'Yes'
		WHEN ci.HomeOwnerFlag = 0 THEN 'No'
		ELSE 'Unknown'
		END AS HomeOwner_Status,

	CAST(ROUND(ISNULL(ci.TotalPurchaseYTD, 0.0),2) AS decimal(18,2)) AS Total_Purchase_YTD,

	CASE	
		WHEN ci.TotalPurchaseYTD < 0 THEN 'Refund/Negative'
		WHEN ci.TotalPurchaseYTD BETWEEN 0 AND 500 THEN 'Low (0-500)'
		WHEN ci.TotalPurchaseYTD BETWEEN 501 AND 2000 THEN 'Mid (501-2000)'
		WHEN ci.TotalPurchaseYTD > 2000 THEN 'High (2000+)'
		ELSE 'Unknown'
	END AS Spending_Bracket,


	--Dates / flags
	TRY_CAST(ci.DateFirstPurchase AS date) AS First_Purchase_Date,
	YEAR(ci.DateFirstPurchase) AS First_Purchase_Year,
	MONTH(ci.DateFirstPurchase ) AS First_Purchase_Month
 
FROM dbo.CustomerInfo_backup ci;
GO