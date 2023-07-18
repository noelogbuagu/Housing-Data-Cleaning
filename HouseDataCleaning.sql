-- Cleaning Data Using SQL Queries

-- CLEANING 1

SELECT
    *
FROM
    dbo.HousingData
GO

-- Standardize SaleDate
SELECT
    SaleDate,
    CONVERT(date, SaleDate)
FROM
    dbo.HousingData
GO

-- Update rows in table '[HousingData]' in schema '[dbo]'
UPDATE [dbo].HousingData
SET
    [SaleDate] = CONVERT(date, SaleDate)
GO

SELECT
    SaleDate
FROM
    dbo.HousingData
GO

-- CLEANING 2

-- Populating Property Address Data
SELECT
    *
FROM
    dbo.HousingData
-- WHERE
--     PropertyAddress IS NULL
ORDER BY
    ParcelID
GO

-- On inspection of query results, there are PropertyAddresses with NULL values
-- However, when the data is Ordered by the ParcelID it can be observed that identical ParcelID's have the same PropertyAddress
-- The idea is to search amongst the rows of data that have NULL PropertyAddresses and cross reference with ParcelID
-- Then populate where there is a match
-- To accomplish this self cross referencing, a self join is done on the HousingData table

SELECT
    Data_1.UniqueID,
    Data_1.ParcelID,
    Data_1.PropertyAddress,
    Data_2.UniqueID,
    Data_2.ParcelID,
    Data_2.PropertyAddress,
    -- To get the column that will be used to update the original table
    -- where the PropertyAddress column had Null values ISNULL() is used
    ISNULL(Data_1.PropertyAddress, Data_2.PropertyAddress) AS Replacement_column
FROM
    dbo.HousingData AS Data_1
JOIN
    dbo.HousingData AS Data_2
ON 
    Data_1.ParcelID = Data_2.ParcelID
    AND
    Data_1.UniqueID <> Data_2.UniqueID
WHERE
    Data_1.PropertyAddress IS NULL

-- Now to Update NULL Data_1.PropertyAddress rows with Replacement_column rows
-- Update rows in table '[HousingData]]' in schema '[dbo]'
UPDATE Data_1
SET
    PropertyAddress = ISNULL(Data_1.PropertyAddress, Data_2.PropertyAddress)
FROM
    dbo.HousingData AS Data_1
JOIN
    dbo.HousingData AS Data_2
ON 
    Data_1.ParcelID = Data_2.ParcelID
    AND
    Data_1.UniqueID != Data_2.UniqueID
WHERE
    Data_1.PropertyAddress IS NULL

-- Query returns 0 NULL PropertyAddress rows    
SELECT
    PropertyAddress
FROM
    dbo.HousingData
WHERE
    PropertyAddress IS NULL
GO

-- CLEANING 3

-- Separating PropertyAddress into individual columns (Address, State, City)
SELECT 
    PropertyAddress
FROM 
    [dbo].HousingData
GO

-- SUBSTRING() EXTRACTS SUBSTRING FROM STRING
-- CHARINDEX() RETURNS INDEX OF SEARCH EXPRESSION FROM EXPRESSION TO BE SEARCHED
SELECT 
    -- CHARINDEX() SERVES AS THE LEN IN THE SUBSTRING FUNCTION
    -- -1 MAKES SURE THE ',' ISN'T RETURNED
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
    -- +1 makes sure the start position is after the ','
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM 
    [dbo].HousingData
GO

-- Now to make the search results permanent and alter the table

-- For Address

ALTER TABLE 
    [dbo].[HousingData]
ADD 
    [PropertySplitAddress] /*new_column_name*/ NVARCHAR(255) /*new_column_datatype*/ 
GO

UPDATE 
    [dbo].HousingData
SET
    [PropertySplitAddress]= SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
GO

-- For City
ALTER TABLE 
    [dbo].[HousingData]
ADD 
    [PropertySplitCity] /*new_column_name*/ NVARCHAR(255) /*new_column_datatype*/ 
GO

UPDATE 
    [dbo].HousingData
SET
    [PropertySplitCity]= SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
GO

-- NOW TO REPEAT FOR OWNERaddress
-- Alternative to SUBSTRING()- PARSENAME()

SELECT 
    -- PARSENAME() splits the expression based on '.'
    -- However, to getthe first expression, the number for the object part starts from the last
    -- for example (obi.oli.nkem)
    -- PARSENAME((obi.oli.nkem),1) would return nkem ,2 would return oli and 3 would return obi
    -- Replace() searches and expression and replaces the searched content with a stated replacement
    PARSENAME(REPLACE(OwnerAddress, ',','.'),3) AS OwnerAddress, 
    PARSENAME(REPLACE(OwnerAddress, ',','.'),2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',','.'),1) AS OwnerState
FROM 
    [dbo].HousingData
GO

-- For OwnerAddress

ALTER TABLE 
    [dbo].[HousingData]
ADD 
    [NewOwnerAddress] /*new_column_name*/ NVARCHAR(255) /*new_column_datatype*/ 
GO

UPDATE 
    [dbo].HousingData
SET
    [NewOwnerAddress]= PARSENAME(REPLACE(OwnerAddress, ',','.'),3)
GO

-- For City
ALTER TABLE 
    [dbo].[HousingData]
ADD 
    [OwnerCity] /*new_column_name*/ NVARCHAR(255) /*new_column_datatype*/ 
GO

UPDATE 
    [dbo].HousingData
SET
    [OwnerCity]= PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
GO

-- For State
ALTER TABLE 
    [dbo].[HousingData]
ADD 
    [OwnerState] /*new_column_name*/ NVARCHAR(255) /*new_column_datatype*/ 
GO

UPDATE 
    [dbo].HousingData
SET
    [OwnerState]= PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
GO

-- Now cross-check
SELECT 
*
FROM 
    [dbo].HousingData
GO

-- CLEANING 3

-- changing Y and N in SoldVacant to Yes and No
SELECT 
    DISTINCT(SoldAsVacant),
    COUNT(SoldAsVacant)
FROM 
    [dbo].HousingData
GROUP BY
    SoldAsVacant
ORDER BY
    2
GO

-- Using CASE to replace Y and N
SELECT 
    SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'YES'
        WHEN SoldAsVacant = 'N' THEN 'NO'
        ELSE SoldAsVacant
    END
FROM 
    [dbo].HousingData
GO

UPDATE [dbo].HousingData
SET
    SoldAsVacant = 
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'YES'
        WHEN SoldAsVacant = 'N' THEN 'NO'
        ELSE SoldAsVacant
    END
GO

-- CLEANING 4

-- Remove duplicates
-- Using CTE
WITH 
    row_num_CTE
AS
(
    SELECT
        *,
        ROW_NUMBER() OVER(
            -- PARTITION THE DATA ON ATRRIBUTES THAT SHOULD BE UNIQUE TO EACH ROW
            PARTITION BY
                ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                    UniqueID
        ) AS row_num
    FROM 
        [dbo].HousingData
    -- ORDER BY
    --     ParcelID
)
SELECT
    *
-- We have to delete duplicate rows, no need to order data
-- DELETE
FROM
    row_num_CTE
WHERE
    row_num > 1
-- ORDER BY
--     PropertyAddress
GO

-- CLEANING 5

-- deleting unused columns
SELECT 
*
FROM 
    [dbo].HousingData
GO

ALTER TABLE 
    [dbo].[HousingData]
DROP COLUMN
    PropertyAddress,
    OwnerAddress,
    TaxDistrict
GO
