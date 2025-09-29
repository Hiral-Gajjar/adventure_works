SELECT * FROM [Person].[Address]
SELECT * FROM [Person].[AddressType]
SELECT * FROM [Person].[BusinessEntity]
SELECT * FROM [Person].[BusinessEntityAddress]
SELECT * FROM [Person].[BusinessEntityContact]
SELECT * FROM [Person].[ContactType]
SELECT * FROM [Person].[EmailAddress]
SELECT * FROM [Person].[CountryRegion]
SELECT * FROM [Person].[Password]
SELECT * FROM [Person].[Person]
SELECT * FROM [Person].[PersonPhone]
SELECT * FROM [Person].[PhoneNumberType]
SELECT * FROM [Person].[StateProvince]




WITH LatestAddresses AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY BusinessEntityID
		ORDER BY ModifiedDate DESC
	) AS rn_la
	FROM [Person].[BusinessEntityAddress]
),
UpdatedBusinessContacts AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY BusinessEntityID
		ORDER BY ModifiedDate DESC
	) AS rn_bc
	FROM [Person].[BusinessEntityContact]
),
LatestEmails AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY BusinessEntityID
		ORDER BY ModifiedDate DESC
		) AS rn_le
	FROM [Person].[EmailAddress]
),

DemographicsExtracted AS (
	SELECT 
		BusinessEntityID, 
		Demographics.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
			(/IndividualSurvey/TotalPurchaseYTD)[1]', 'decimal(18,2)') AS TotalPurchaseYTD,
		Demographics.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
			(/IndividualSurvey/DateFirstPurchase)[1]', 'date') AS DateFirstPurchase,
		Demographics.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
			(/IndividualSurvey/Education)[1]', 'nvarchar(50)') AS Education,
		Demographics.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
			(/IndividualSurvey/MaritalStatus)[1]', 'nvarchar(10)') AS MaritalStatus,
		Demographics.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey";
			(/IndividualSurvey/HomeOwnerFlag)[1]', 'bit') AS HomeOwnerFlag
	FROM [Person].[Person]
	WHERE Demographics IS NOT NULL
)

SELECT 
--Address
addr.AddressID AS AddressID,
addr.AddressLine1 AS AddressLine1,
addr.AddressLine2 AS AddressLine2,
addr.city AS City,
addr.StateProvinceID AS StateProvinceID,
addr.PostalCode AS PostalCode,
addr.SpatialLocation AS SpatialLocation,

--AddressType
addtype.AddressTypeID AS AddressTypeID,
addtype.Name AS AddressName,

--BusinessEntity
busent.BusinessEntityID AS BusinessEntityID,

--BusinessEntityContact
buscontact.PersonID AS PersonID,
buscontact.ContactTypeID,

--ContactType
conttype.Name AS ContactName,

--CountryRegion
reg.CountryRegionCode AS CountryRegionCode,
reg.Name AS CountryName,

--EmailAddress
email.EmailAddressID AS EmailAdressID,
email.Emailaddress AS EmailAddress,

--Password
pswrd.PasswordHash AS LongPassword,
pswrd.PasswordSalt AS ShortPassword,

--Person
person.PersonType AS PersonType,
person.NameStyle AS NameStyle,
person.Title AS Title,
person.FirstName AS FirstName,
person.MiddleName AS MiddleName,
person.LastName AS LastName,
person.Suffix AS Suffix,
person.EmailPromotion AS EmailPromotion,


--Person - Demographics Column 
demo.TotalPurchaseYTD AS TotalPurchaseYTD,
demo.DateFirstPurchase AS DateFirstPurchase,
demo.Education AS EducationLevel,
demo.MaritalStatus AS MaritalStatus,
demo.HomeOwnerFlag AS HomeOwnerFlag,

--PersonPhone
phn.PhoneNumber AS PhoneNumber,
phn.PhoneNumberTypeID AS PhoneNumberTypeID,

--PhoneNumberType
phntyp.Name AS PhoneType,

--StateProvince
prv.StateProvinceCode AS StateProvinceCode,
prv.IsOnlyStateProvinceFlag AS StateProvinceFlag,
prv.Name AS ProvinceName,
prv.TerritoryID AS TerritoryID

INTO CustomerInfo

FROM LatestAddresses AS busadd
LEFT JOIN [Person].[Address] AS addr
	ON busadd.AddressID = addr.AddressID
LEFT JOIN [Person].[AddressType] AS addtype
	ON busadd.AddressTypeID = addtype.AddressTypeID
LEFT JOIN  [Person].[BusinessEntity] AS busent
	ON busadd.BusinessEntityID = busent.BusinessEntityID
LEFT JOIN UpdatedBusinessContacts AS buscontact
	ON busadd.BusinessEntityID = buscontact.BusinessEntityID
	AND buscontact.rn_bc = 1
LEFT JOIN [Person].[ContactType] AS conttype
	ON buscontact.ContactTypeID = conttype.ContactTypeID
LEFT JOIN LatestEmails AS email
	ON busadd.BusinessEntityID = email.BusinessEntityID
	AND email.rn_le = 1	
LEFT JOIN [Person].[Password] AS pswrd
	ON busadd.BusinessEntityID = pswrd.BusinessEntityID
LEFT JOIN [Person].[Person] AS person
	ON busadd.BusinessEntityID = person.BusinessEntityID
LEFT JOIN DemographicsExtracted AS demo
	ON person.BusinessEntityID = demo.BusinessEntityID
LEFT JOIN [Person].[PersonPhone] AS phn
	ON busadd.BusinessEntityID = phn.BusinessEntityID
LEFT JOIN [Person].[PhoneNumberType] AS phntyp
	ON phn.PhoneNumberTypeID = phntyp.PhoneNumberTypeID
LEFT JOIN [Person].[StateProvince] AS prv
	ON addr.StateProvinceID = prv.StateProvinceID
LEFT JOIN [Person].[CountryRegion] AS reg
	ON prv.CountryRegionCode = reg.CountryRegionCode
WHERE busadd.rn_la = 1
	

