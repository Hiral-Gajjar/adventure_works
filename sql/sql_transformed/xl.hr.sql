CREATE OR ALTER VIEW xl.HR AS

SELECT 
	
	--Core
	hr.EmployeeID AS Employee_ID, 
	ISNULL(hr.EmployeeJobTitle, '') AS Job_Title, 
	ISNULL(hr.DepartmentName, '') AS Department,
	ISNULL(hr.ShiftName, '') AS Shift,
	CAST(ISNULL(hr.IsSalaried, 0) AS bit) AS Is_Salaried,
	CAST(ISNULL(hr.IsActiveEmployee,0)AS bit) AS Is_Active,

	--People
	ISNULL(NULLIF(LTRIM(RTRIM(hr.EmployeeGender)), ''), 'Unknown') AS Gender,
	ISNULL(hr.EmployeeMaritalStatus, '') AS Marital_Status,

	--Dates
	TRY_CAST(hr.EmployeeBirthDate AS date) AS Birth_Date,
	TRY_CAST(hr.EmployeeHireDate AS date) AS Hire_Date,
	TRY_CAST(hr.JobStartDate AS date) AS Job_Start_Date,
	CAST(ROUND(DATEDIFF(day, hr.JobStartDate, GETDATE())/ 365.25, 2) AS decimal(6,2)) AS Tenure_Years,

	--Derived Age + Group
	CASE 
      WHEN DATEADD(year, DATEDIFF(year, hr.EmployeeBirthDate, GETDATE()), hr.EmployeeBirthDate) > GETDATE()
        THEN DATEDIFF(year, hr.EmployeeBirthDate, GETDATE()) - 1
      ELSE DATEDIFF(year, hr.EmployeeBirthDate, GETDATE())
    END AS Age,

	CASE 
      WHEN DATEADD(year, DATEDIFF(year, hr.EmployeeBirthDate, GETDATE()), hr.EmployeeBirthDate) > GETDATE()
        THEN DATEDIFF(year, hr.EmployeeBirthDate, GETDATE()) - 1
      ELSE DATEDIFF(year, hr.EmployeeBirthDate, GETDATE())
    END / 10 * 10 AS Age_Bucket_Start,

	--Pay & Leave
	CAST(ROUND(ISNULL(hr.PayRate, 0.0), 2) AS decimal(18,2)) AS Pay_Rate,
	ISNULL(hr.EmployeeVacationHours, 0) AS Vacation_Hours,
	ISNULL(hr.EmployeeSickLeaveHours, 0) AS Sick_Leave_Hours

FROM HumanResources_curated hr;
GO