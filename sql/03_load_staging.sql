USE retail_banking_dw;
GO

-- SQL Server service account must be able to read these local paths.
-- Refresh staging tables before each load so rerunning this script
-- does not append duplicate source rows.
-- CSV files use CRLF. With LF (0x0a) as row terminator, CHAR(13) can remain
-- in the final column. The transformation scripts remove it.
TRUNCATE TABLE stg.transactions;
TRUNCATE TABLE stg.accounts;
TRUNCATE TABLE stg.customers;

BULK INSERT stg.customers
FROM 'D:\SKRIPSI\PORTFOLIO\retail-banking-data-pipeline\data\raw\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char'
);

BULK INSERT stg.accounts
FROM 'D:\SKRIPSI\PORTFOLIO\retail-banking-data-pipeline\data\raw\accounts.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char'
);

BULK INSERT stg.transactions
FROM 'D:\SKRIPSI\PORTFOLIO\retail-banking-data-pipeline\data\raw\transactions.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char'
);

-- Expected after one load: 1,001 customers; 1,800 accounts; 20,005 transactions.
SELECT 'customers' AS source_table, COUNT(*) AS row_count FROM stg.customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM stg.accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM stg.transactions;
GO
