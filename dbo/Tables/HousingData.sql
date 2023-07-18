CREATE TABLE [dbo].[HousingData] (
    [UniqueID]        INT            NOT NULL,
    [ParcelID]        NVARCHAR (50)  NOT NULL,
    [LandUse]         NVARCHAR (50)  NOT NULL,
    [PropertyAddress] NVARCHAR (50)  NULL,
    [SaleDate]        DATE           NOT NULL,
    [SalePrice]       FLOAT (53)     NOT NULL,
    [LegalReference]  NVARCHAR (50)  NOT NULL,
    [SoldAsVacant]    NVARCHAR (50)  NOT NULL,
    [OwnerName]       NVARCHAR (100) NULL,
    [OwnerAddress]    NVARCHAR (50)  NULL,
    [Acreage]         FLOAT (53)     NULL,
    [TaxDistrict]     NVARCHAR (50)  NULL,
    [LandValue]       INT            NULL,
    [BuildingValue]   INT            NULL,
    [TotalValue]      INT            NULL,
    [YearBuilt]       SMALLINT       NULL,
    [Bedrooms]        TINYINT        NULL,
    [FullBath]        TINYINT        NULL,
    [HalfBath]        TINYINT        NULL
);


GO

