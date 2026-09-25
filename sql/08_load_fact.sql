USE retail_banking_dw;
GO

WITH cleaned_transaction AS (
    SELECT LTRIM(RTRIM(transaction_id)) AS transaction_id,
           LTRIM(RTRIM(account_id)) AS account_id,
           COALESCE(
               TRY_CONVERT(DATE, LTRIM(RTRIM(transaction_date)), 23),
               TRY_CONVERT(DATE, LTRIM(RTRIM(transaction_date)), 103)
           ) AS transaction_date,
           UPPER(LTRIM(RTRIM(transaction_type))) AS transaction_type,
           TRY_CONVERT(
               DECIMAL(18,2),
               NULLIF(LTRIM(RTRIM(REPLACE(amount, CHAR(13), ''))), '')
           ) AS amount
    FROM stg.transactions
), ranked_transaction AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id
               ORDER BY transaction_date, account_id
           ) AS rn
    FROM cleaned_transaction
)
INSERT INTO dw.fact_transaction
    (transaction_id, account_key, transaction_date, transaction_type, amount)
SELECT t.transaction_id,
       a.account_key,
       t.transaction_date,
       t.transaction_type,
       t.amount
FROM ranked_transaction AS t
INNER JOIN dw.dim_account AS a
    ON t.account_id = a.account_id
WHERE t.rn = 1
  AND t.transaction_date IS NOT NULL
  AND t.amount IS NOT NULL
  AND t.amount > 0
  AND t.transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')
  AND NOT EXISTS (
      SELECT 1
      FROM dw.fact_transaction AS existing
      WHERE existing.transaction_id = t.transaction_id
  );

-- Expected: 19,954 rows after deduplication and validation.
SELECT COUNT(*) AS fact_rows FROM dw.fact_transaction;

SELECT transaction_id, COUNT(*) AS row_count
FROM dw.fact_transaction
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT TOP 10
       transaction_key, transaction_id, account_key,
       transaction_date, transaction_type, amount
FROM dw.fact_transaction
ORDER BY transaction_key;
GO
