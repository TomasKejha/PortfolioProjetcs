-- CLEANING DATA ABOUT NASHVILLE HOUSING USING SQL


-- SOFTWARE: DBeaver 22.2.4
-- RDBMS: MySQL
-- DATA SOURCE: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx

-- I created a copy of the raw data so I am able to alter the table

-- Improting data
	/* I had to change a column name from 'UniqueID ' to 'UniqueID' and change a few numeric values from '$value' to 'value'
		to be able to import the data
		- I used Google Sheets because of the convenient 'Find and replace' function */

	
-- CHANGING 'SalesDate' FROM 'datetime' TO 'date'
	
	
SELECT
	CAST(SaleDate AS Date)
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	
	
-- POPULATING 'PropertyAddress'

	
SELECT												-- I found out there are 27 NULL values in 'PropertyAddress'
	PropertyAddress 
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
WHERE
	PropertyAddress = 'NULL'
	
	
SELECT												-- The data is stored in such a way that when 'ParcelID' has
	ParcelID, PropertyAddress 								-- the same value for multiple rows, the 'PropertyAdress' value
FROM												-- is only shown in the first row and the other rows have
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx				-- NULL value
												-- We can use this insight to populate the NULL values using 'self join'
	
SELECT												-- Using 'UniqueID' allows us to query only the rows
	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress				-- that have NULL value in 'PropertyAddress' in tahble b
FROM												-- and NON-NULL value in 'PropertyAddress' in table b
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx AS a
	JOIN nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx as b
	ON a.ParcelID = b.ParcelID AND
	   a.UniqueID <> b.UniqueID
WHERE
	a.PropertyAddress = 'NULL'
	
	
UPDATE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx AS a			-- Populating 'PropertyAddress'													
	JOIN nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx as b
	ON a.ParcelID = b.ParcelID AND
	   a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress 
WHERE
	a.PropertyAddress = 'NULL'
	
	
-- SPLITTING 'PropertyAddress' INTO INDIVIDUAL COLUMNS

	
SELECT												-- 'PropertyAddress' conveniently uses ',' as a delimiter
	PropertyAddress
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	
	
SELECT
	SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,					-- Quering a new column 'Address'
	SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City					-- Quering a new column 'City'
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	
	
ALTER TABLE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx			-- Creating a new column 'PropertySplitAddress'
ADD PropertySplitAddress VARCHAR(255)

UPDATE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx				-- Populating 'PropertySplitAddress'
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1)
	

ALTER TABLE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx			-- Creating a new column 'PropertySplitCity'
ADD PropertySplitCity VARCHAR(255)

UPDATE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx				-- Populating 'PropertySplitCity'
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1)


-- SPLITTING 'OwnerAddress' INTO INDIVIDUAL COLUMNS


SELECT												-- 'OwnerAdress' consists of adress, city, and state separated
	OwnerAddress 										-- by ',' delimiters
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx


SELECT
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,					-- Quering a new column 'Address'
	SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,		-- Quering a new column 'City'
	SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State						-- Quering a new column 'State'
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	
	
ALTER TABLE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx			-- Creating a new columns
ADD (OwnerSplitAddress VARCHAR(255),
     OwnerSplitCity VARCHAR(255),
     OwnerSplitState VARCHAR(255)
    )
	
	
UPDATE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx				-- Populating new columns
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
    OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1)
	 
	 
-- CHANGING 'Y' AND 'N' TO 'YES' AND 'NO' IN 'SoldAsVacant'
	-- 'SoldAsVacant' originally included all four options (Y, N, Yes, no)
	
	
SELECT												-- Creating case statement
	DISTINCT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END	
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	
	
UPDATE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx				-- Updating the table
SET SoldAsVacant = CASE
			WHEN SoldAsVacant = 'N' THEN 'No'
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			ELSE SoldAsVacant
                   END	


-- REMOVING DUPILCATES

					
WITH RowNumCTE  AS (										-- Using CTE(Common Table Expression) and ROW_NUMBER function
SELECT												-- to find duplicate values
	*,
	ROW_NUMBER() OVER(PARTITION BY 
					ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
			  ) AS Row_Num
FROM
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	           )	
					
DELETE FROM											-- Deleting the duplicate values using CTE
	nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	USING
		nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx
	JOIN RowNumCTE
	 ON nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx.UniqueID = RowNumCTE.UniqueID
WHERE
	RowNumCTE.Row_Num > 1
		
	
-- DELETE UNNECESSARY COLUMNS	
	
	
ALTER TABLE nashvillehousing.nashville_housing_data_for_data_cleaning_xlsx			-- Finishing by dropping unwanted columns
DROP COLUMN PropertyAddress,
DROP COLUMN	OwnerAddress,
DROP COLUMN	TaxDistrict

	
	
					
					
