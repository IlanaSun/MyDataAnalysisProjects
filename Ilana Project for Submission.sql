-- qu 1

USE AdventureWorks2019
SELECT p.ProductID, p.Name AS ProductName, p. Color, p.ListPrice, Size
FROM Production.Product AS p 
WHERE ProductID NOT IN (SELECT  ProductID
						FROM Sales.SalesOrderDetail)
ORDER BY p.ProductID

-- qu 2

WITH CTE (CustomerID)
AS
		(SELECT c.CustomerID AS CustomerID
		FROM Sales.Customer AS c
		WHERE c.CustomerID NOT IN (SELECT CustomerID
						FROM Sales.SalesOrderHeader))

SELECT c.CustomerID, ISNULL(p.LastName, 'Unknown') AS LastName, ISNULL (p.FirstName, 'Unknown') AS FirstName 
FROM CTE AS c LEFT JOIN Person.Person AS p ON c.CustomerID = p.BusinessEntityID
ORDER BY 1

-- qu 3

	SELECT TOP(10) c.CustomerID, p.FirstName, p.LastName, COUNT(s.SalesOrderID) AS CountOfOrders
	FROM Sales.Customer AS c  JOIN Sales.SalesOrderHeader AS s ON s.CustomerID=c.CustomerID
		  JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
	GROUP BY c.CustomerID, p.FirstName, p.LastName
ORDER BY CountOfOrders DESC

-- qu 4

SELECT p.FirstName, p.LastName, e.JobTitle, e.HireDate, COUNT(e.JobTitle) OVER (Partition BY e.JobTitle ORDER BY JobTitle) AS CountOfTitle
FROM Person.Person AS p JOIN HumanResources.Employee AS e ON p.BusinessEntityID = e.BusinessEntityID
GROUP BY e.JobTitle, p.FirstName, p.LastName,  e.HireDate

-- qu 5

SELECT SalesOrderID, CustomerID, LastName, FirstName, 
			OrderDate, PreviousOrder
FROM(
	SELECT s.SalesOrderID, c.CustomerID, p.LastName, p.FirstName, 
			s.OrderDate, row_number() OVER (Partition by c.CustomerID ORDER BY s.OrderDate DESC) AS rn, 
			LAG(OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY OrderDate) AS PreviousOrder
	FROM Sales.SalesOrderHeader AS s LEFT JOIN Sales.Customer AS c ON s.CustomerID=c.CustomerID
		  LEFT JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
		  ) sdf
WHERE rn = 1
ORDER BY CustomerID

-- qu 6

WITH cte

AS
	(
	SELECT *
	FROM (
		SELECT SalesOrderID, YEAR(ModifiedDate) AS 'Year', 
			FORMAT(SUM(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty), 'N')AS Total,
			ROW_NUMBER () OVER (Partition by YEAR(ModifiedDate) 
			ORDER BY (SUM(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty))DESC) AS rn
		FROM Sales.SalesOrderDetail AS sod
		GROUP BY SalesOrderID, YEAR(ModifiedDate)
		) asd
	WHERE rn = 1
	)

SELECT c.Year, soh.SalesOrderID, p.LastName, p.FirstName, c.Total
FROM cte AS c JOIN Sales.SalesOrderHeader AS soh ON c.SalesOrderID = soh.SalesOrderID
	JOIN Sales.Customer AS s ON soh.CustomerID = s.CustomerID
	JOIN Person.Person AS p ON s.PersonID = p.BusinessEntityID

	--qu 7
SELECT Month, [2011], [2012], [2013], [2014]
FROM 
	(SELECT YEAR(OrderDate) AS y, MONTH(OrderDate) AS 'Month', SalesOrderID 
	FROM Sales.SalesOrderHeader) o
Pivot (COUNT (SalesOrderID) for y in ([2011], [2012], [2013], [2014]))p
Order by 1

-- qu 8
CREATE TABLE smp
(Year_ int,
Month_ int,
Sum_Price Money)
INSERT INTO smp 
	SELECT Year(h.OrderDate) AS 'Year_', MONTH(h.OrderDate) AS 'Month_', SUM((sod.UnitPrice-sod.UnitPriceDiscount)) AS Sum_Price
	FROM Sales.SalesOrderHeader AS h JOIN Sales.SalesOrderDetail AS sod ON h.SalesOrderID = sod.SalesOrderID
	GROUP BY ROLLUP (Year(h.OrderDate), MONTH(h.OrderDate))
	
UPDATE smp
SET Sum_price= 0
WHERE Month_ IS NULL

UPDATE smp
SET Month_ = 13
WHERE Month_ IS NULL

UPDATE smp
SET Sum_price= NULL
WHERE Month_ = 13

SELECT Year_ AS 'Year', CAST (REPLACE(Month_,13,'grand_total') AS varchar(20)) AS 'Month',
	FORMAT(Sum_Price, 'N') AS Sum_Price, FORMAT(SUM(Sum_Price)OVER(Partition by Year_ Order by Month_),'N') AS Cuml_Sum
FROM smp
WHERE Year_ is not null
GROUP BY Year_, Month_, Sum_Price


-- qu 9
SELECT *, DATEDIFF(DAY, PreviousEmpHDate, HireDate) AS DiffDays
FROM (
	SELECT d.Name AS DepartmentName, e.BusinessEntityID, p.FirstName + ' '+ p.LastName AS 'Employee"sFullName', 
			e.HireDate, DATEDIFF(MONTH, e.HireDate, GETDATE()) AS Seniority, 
			LAG(p.FirstName + ' '+ p.LastName) OVER (PARTITION BY d.Name ORDER BY e.Hiredate) AS PreviousEmpName,
			LAG (e.HireDate) OVER (PARTITION BY d.Name ORDER BY e.Hiredate) AS PreviousEmpHDate
	FROM HumanResources.Department AS d JOIN HumanResources.EmployeeDepartmentHistory AS h ON d.DepartmentID = h.DepartmentID
		JOIN HumanResources.Employee AS e ON e.BusinessEntityID = h.BusinessEntityID
		JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
	) asd
ORDER BY 1, 2 DESC

-- qu 10
WITH cteemp
AS (
SELECT e.HireDate, h.DepartmentID, CONCAT(e.BusinessEntityID, ' ', p.LastName, ' ', p.Firstname) AS TeamEmployees
FROM HumanResources.Department AS d JOIN HumanResources.EmployeeDepartmentHistory AS h ON d.DepartmentID = h.DepartmentID
		JOIN HumanResources.Employee AS e ON e.BusinessEntityID = h.BusinessEntityID
		JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
	)
SELECT HireDate, DepartmentID, STRING_AGG(TeamEmployees, ', ') AS TeamEmployees
FROM cteemp
GROUP BY HireDate, DepartmentID
ORDER BY HireDate DESC

--qu 10 without dept

WITH cteemp
AS (
SELECT DISTINCT e.HireDate, CONCAT(e.BusinessEntityID, ' ', p.LastName, ' ', p.Firstname) AS TeamEmployees
FROM HumanResources.Department AS d JOIN HumanResources.EmployeeDepartmentHistory AS h ON d.DepartmentID = h.DepartmentID
		JOIN HumanResources.Employee AS e ON e.BusinessEntityID = h.BusinessEntityID
		JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
	)
SELECT HireDate, STRING_AGG(TeamEmployees, ', ') AS TeamEmployees
FROM cteemp
GROUP BY HireDate
ORDER BY HireDate DESC