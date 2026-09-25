USE retail_banking_dw;
GO

-- Staging keeps source values as text before cleansing, including dirty records.
-- No PK/FK constraints here: duplicates and invalid references must remain visible.
IF OBJECT_ID(N'stg.customers', N'U') IS NULL
BEGIN
    CREATE TABLE stg.customers (
        customer_id NVARCHAR(50),
        customer_name NVARCHAR(100),
        city NVARCHAR(100),
        registration_date NVARCHAR(50)
    );
END;

IF OBJECT_ID(N'stg.accounts', N'U') IS NULL
BEGIN
    CREATE TABLE stg.accounts (
        account_id NVARCHAR(50),
        customer_id NVARCHAR(50),
        account_type NVARCHAR(50),
        opening_date NVARCHAR(50),
        status NVARCHAR(50)
    );
END;

IF OBJECT_ID(N'stg.transactions', N'U') IS NULL
BEGIN
    CREATE TABLE stg.transactions (
        transaction_id NVARCHAR(50),
        account_id NVARCHAR(50),
        transaction_date NVARCHAR(50),
        transaction_type NVARCHAR(50),
        amount NVARCHAR(50)
    );
END;
GO
