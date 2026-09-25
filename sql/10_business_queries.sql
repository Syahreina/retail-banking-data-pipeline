USE retail_banking_dw;
GO

-- A. Top customers by transaction value
SELECT TOP 10
       customer_id,
       customer_name,
       city,
       total_accounts,
       total_transactions,
       total_transaction_amount
FROM mart.customer_transaction_summary
ORDER BY total_transaction_amount DESC, customer_id;

-- B. Transaction performance by city
SELECT city,
       COUNT(*) AS total_customers,
       SUM(total_accounts) AS total_accounts,
       SUM(total_transactions) AS total_transactions,
       SUM(total_transaction_amount) AS total_transaction_amount,
       CAST(AVG(total_transaction_amount) AS DECIMAL(18,2))
           AS avg_transaction_amount_per_customer
FROM mart.customer_transaction_summary
GROUP BY city
ORDER BY total_transaction_amount DESC;

-- C. Transaction breakdown by type
SELECT transaction_type,
       COUNT(*) AS total_transactions,
       SUM(amount) AS total_amount,
       CAST(AVG(amount) AS DECIMAL(18,2)) AS avg_amount
FROM dw.fact_transaction
GROUP BY transaction_type
ORDER BY transaction_type;
GO
