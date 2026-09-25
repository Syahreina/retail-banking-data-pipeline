USE retail_banking_dw;
GO

-- Grain: one row per customer.
IF OBJECT_ID(N'mart.customer_transaction_summary', N'U') IS NULL
BEGIN
    CREATE TABLE mart.customer_transaction_summary (
        customer_key INT PRIMARY KEY,
        customer_id NVARCHAR(50),
        customer_name NVARCHAR(100),
        city NVARCHAR(100),
        total_accounts INT,
        total_transactions INT,
        total_deposit_amount DECIMAL(18,2),
        total_withdrawal_amount DECIMAL(18,2),
        total_transfer_amount DECIMAL(18,2),
        total_transaction_amount DECIMAL(18,2),
        first_transaction_date DATE,
        last_transaction_date DATE
    );
END;

-- Refresh the summary from the current warehouse dimensions and fact.
DELETE FROM mart.customer_transaction_summary;

INSERT INTO mart.customer_transaction_summary (
    customer_key, customer_id, customer_name, city,
    total_accounts, total_transactions,
    total_deposit_amount, total_withdrawal_amount, total_transfer_amount,
    total_transaction_amount, first_transaction_date, last_transaction_date
)
SELECT c.customer_key,
       c.customer_id,
       c.customer_name,
       c.city,
       COUNT(DISTINCT a.account_key) AS total_accounts,
       COUNT(f.transaction_key) AS total_transactions,
       COALESCE(SUM(CASE WHEN f.transaction_type = 'DEPOSIT' THEN f.amount ELSE 0 END), 0)
           AS total_deposit_amount,
       COALESCE(SUM(CASE WHEN f.transaction_type = 'WITHDRAWAL' THEN f.amount ELSE 0 END), 0)
           AS total_withdrawal_amount,
       COALESCE(SUM(CASE WHEN f.transaction_type = 'TRANSFER' THEN f.amount ELSE 0 END), 0)
           AS total_transfer_amount,
       COALESCE(SUM(f.amount), 0) AS total_transaction_amount,
       MIN(f.transaction_date) AS first_transaction_date,
       MAX(f.transaction_date) AS last_transaction_date
FROM dw.dim_customer AS c
LEFT JOIN dw.dim_account AS a
    ON c.customer_key = a.customer_key
LEFT JOIN dw.fact_transaction AS f
    ON a.account_key = f.account_key
GROUP BY c.customer_key, c.customer_id, c.customer_name, c.city;

-- Expected: 1,000 customer summary rows.
SELECT COUNT(*) AS mart_rows
FROM mart.customer_transaction_summary;
GO
