SELECT 
dept.DepartmentID AS DepartmentID, 
dept.Name AS DepartmentName, 
dept.GroupName AS DepartmentGroupName,

emp.BusinessEntityID AS EmployeeID,
emp.NationalIDNumber AS EmployeeNationalID, 
emp.LoginID AS EmployeeLoginID, 
emp.OrganizationNode AS EmployeeOrgNode, 
emp.OrganizationLevel AS EmployeeOrgLevel, 
emp.JobTitle AS EmployeeJobTitle ,
emp.BirthDate AS EmployeeBirthDate, 
emp.MaritalStatus AS EmployeeMaritalStatus, 
emp.Gender AS EmployeeGender,
emp.HireDate AS EmployeeHireDate, 
emp.SalariedFlag AS IsSalaried, 
emp.VacationHours AS EmployeeVacationHours, 
emp.SickLeaveHours AS EmployeeSickLeaveHours, 
emp.CurrentFlag AS IsActiveEmployee,

emp_dept.ShiftID AS EmployeeShiftID, 
emp_dept.StartDate AS JobStartDate, 
emp_dept.EndDate AS JobEndDate,

emp_pay.RateChangeDate AS PayRateChangeDate , 
emp_pay.Rate AS PayRate, 
emp_pay.PayFrequency AS PayFrequency, 

job_cdt.JobCandidateID as JobCandidateID, 
job_cdt.Resume AS EmployeeResume,

shft.Name AS ShiftName, 
shft.StartTime AS ShiftStartTime, 
shft.EndTime AS ShiftEndTime

INTO HumanResources

FROM [HumanResources].[EmployeeDepartmentHistory] emp_dept 
LEFT JOIN [HumanResources].[Department] dept 
	ON dept.DepartmentID = emp_dept.DepartmentID

LEFT JOIN [HumanResources].[Employee] emp 
	ON emp_dept.BusinessEntityID = emp.BusinessEntityID

OUTER APPLY(
	SELECT TOP 1 RateChangeDate, Rate, PayFrequency 
	FROM [HumanResources].[EmployeePayHistory]
	WHERE BusinessEntityID = emp_dept.BusinessEntityID
	ORDER BY RateChangeDate DESC
	)emp_pay

OUTER APPLY(
	SELECT TOP 1 JobCandidateID, Resume
	FROM [HumanResources].[JobCandidate] 
	WHERE BusinessEntityID = emp_dept.BusinessEntityID
	ORDER BY ModifiedDate DESC
) job_cdt

LEFT JOIN [HumanResources].[Shift] shft 
	ON emp_dept.ShiftID = shft.ShiftID


