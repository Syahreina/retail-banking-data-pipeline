-- Run this script first in SSMS.
IF DB_ID(N'retail_banking_dw') IS NULL
    CREATE DATABASE retail_banking_dw;
GO

USE retail_banking_dw;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'stg')
    EXEC(N'CREATE SCHEMA stg');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dw')
    EXEC(N'CREATE SCHEMA dw');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'mart')
    EXEC(N'CREATE SCHEMA mart');
GO
