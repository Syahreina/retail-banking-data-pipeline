USE retail_banking_dw;
GO

IF OBJECT_ID(N'dw.fact_transaction', N'U') IS NULL
BEGIN
    CREATE TABLE dw.fact_transaction (
        transaction_key INT IDENTITY(1,1) PRIMARY KEY,
        transaction_id NVARCHAR(50) NOT NULL UNIQUE,
        account_key INT NOT NULL,
        transaction_date DATE NOT NULL,
        transaction_type NVARCHAR(20) NOT NULL,
        amount DECIMAL(18,2) NOT NULL,
        CONSTRAINT FK_fact_transaction_account
            FOREIGN KEY (account_key) REFERENCES dw.dim_account(account_key)
    );
END;
GO
