USE retail_banking_dw;
GO

-- ============================================================================
-- A. CUSTOMER DATA QUALITY
-- ============================================================================

-- Duplicate customer IDs (one duplicate row is expected).
SELECT
    customer_id,
    COUNT(*) AS row_count
FROM stg.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Raw city distribution.
-- Binary collation keeps casing differences visible.
SELECT
    city COLLATE Latin1_General_100_BIN2 AS raw_city,
    COUNT(*) AS row_count
FROM stg.customers
GROUP BY city COLLATE Latin1_General_100_BIN2
ORDER BY row_count DESC, raw_city;


-- City values after standardization.
SELECT
    UPPER(LTRIM(RTRIM(city))) AS standardized_city,
    COUNT(*) AS row_count
FROM stg.customers
GROUP BY UPPER(LTRIM(RTRIM(city)))
ORDER BY row_count DESC, standardized_city;


-- Check hidden CHAR(13) in the final CSV column.
SELECT
    ASCII(RIGHT(registration_date, 1)) AS last_character_code,
    COUNT(*) AS row_count
FROM stg.customers
GROUP BY ASCII(RIGHT(registration_date, 1));


-- Validate registration date after removing CHAR(13).
-- Expected invalid_date_count = 0.
SELECT
    COUNT(*) AS invalid_date_count
FROM stg.customers
WHERE TRY_CONVERT(
          DATE,
          NULLIF(
              LTRIM(RTRIM(REPLACE(registration_date, CHAR(13), ''))),
              ''
          ),
          23
      ) IS NULL
  AND NULLIF(
          LTRIM(RTRIM(REPLACE(registration_date, CHAR(13), ''))),
          ''
      ) IS NOT NULL;


-- ============================================================================
-- B. ACCOUNT DATA QUALITY
-- ============================================================================

-- Duplicate account IDs (none expected).
SELECT
    account_id,
    COUNT(*) AS row_count
FROM stg.accounts
GROUP BY account_id
HAVING COUNT(*) > 1;


-- Missing customer IDs (four expected).
SELECT
    COUNT(*) AS missing_customer_id_count
FROM stg.accounts
WHERE customer_id IS NULL
   OR LTRIM(RTRIM(customer_id)) = '';


-- Nonblank customer IDs not found in the staging customer master.
-- Expected orphan_customer_id_count = 0.
SELECT
    COUNT(*) AS orphan_customer_id_count
FROM stg.accounts AS a
LEFT JOIN stg.customers AS c
    ON LTRIM(RTRIM(a.customer_id)) = LTRIM(RTRIM(c.customer_id))
WHERE NULLIF(LTRIM(RTRIM(a.customer_id)), '') IS NOT NULL
  AND c.customer_id IS NULL;


-- Invalid opening dates (none expected).
SELECT
    COUNT(*) AS invalid_opening_date_count
FROM stg.accounts
WHERE TRY_CONVERT(
          DATE,
          NULLIF(
              LTRIM(RTRIM(REPLACE(opening_date, CHAR(13), ''))),
              ''
          ),
          23
      ) IS NULL
  AND NULLIF(
          LTRIM(RTRIM(REPLACE(opening_date, CHAR(13), ''))),
          ''
      ) IS NOT NULL;


-- Check hidden CHAR(13) in the final CSV column.
SELECT
    ASCII(RIGHT(status, 1)) AS last_character_code,
    COUNT(*) AS row_count
FROM stg.accounts
GROUP BY ASCII(RIGHT(status, 1));


-- Standardized account status.
SELECT
    UPPER(
        LTRIM(
            RTRIM(
                REPLACE(status, CHAR(13), '')
            )
        )
    ) AS standardized_status,
    COUNT(*) AS row_count
FROM stg.accounts
GROUP BY
    UPPER(
        LTRIM(
            RTRIM(
                REPLACE(status, CHAR(13), '')
            )
        )
    )
ORDER BY row_count DESC;


-- ============================================================================
-- C. TRANSACTION DATA QUALITY
-- ============================================================================

-- Duplicate transaction IDs (five duplicate IDs expected).
SELECT
    transaction_id,
    COUNT(*) AS row_count
FROM stg.transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- Missing account IDs (eight expected).
SELECT
    COUNT(*) AS missing_account_id_count
FROM stg.transactions
WHERE account_id IS NULL
   OR LTRIM(RTRIM(account_id)) = '';


-- Nonblank account IDs absent from staging account master (ten expected).
SELECT
    COUNT(*) AS orphan_account_id_count
FROM stg.transactions AS t
LEFT JOIN stg.accounts AS a
    ON LTRIM(RTRIM(t.account_id)) = LTRIM(RTRIM(a.account_id))
WHERE NULLIF(LTRIM(RTRIM(t.account_id)), '') IS NOT NULL
  AND a.account_id IS NULL;


-- Check hidden CHAR(13) in the final CSV column.
SELECT
    ASCII(RIGHT(amount, 1)) AS last_character_code,
    COUNT(*) AS row_count
FROM stg.transactions
GROUP BY ASCII(RIGHT(amount, 1));


-- Missing/invalid and negative amount checks.
WITH cleaned_amount AS (
    SELECT
        TRY_CONVERT(
            DECIMAL(18,2),
            NULLIF(
                LTRIM(
                    RTRIM(
                        REPLACE(amount, CHAR(13), '')
                    )
                ),
                ''
            )
        ) AS amount_value
    FROM stg.transactions
)
SELECT
    SUM(
        CASE
            WHEN amount_value IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_or_invalid_amount_count,

    SUM(
        CASE
            WHEN amount_value < 0 THEN 1
            ELSE 0
        END
    ) AS negative_amount_count
FROM cleaned_amount;


-- Raw transaction type distribution.
SELECT
    transaction_type COLLATE Latin1_General_100_BIN2 AS raw_transaction_type,
    COUNT(*) AS row_count
FROM stg.transactions
GROUP BY transaction_type COLLATE Latin1_General_100_BIN2
ORDER BY row_count DESC;


-- Standardized transaction type distribution.
SELECT
    UPPER(LTRIM(RTRIM(transaction_type))) AS standardized_type,
    COUNT(*) AS row_count
FROM stg.transactions
GROUP BY UPPER(LTRIM(RTRIM(transaction_type)))
ORDER BY row_count DESC;


-- Invalid transaction types (ten UNKNOWN rows expected).
SELECT
    COUNT(*) AS invalid_type_count
FROM stg.transactions
WHERE UPPER(LTRIM(RTRIM(transaction_type)))
      NOT IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER');


-- Transaction date profiling.
-- Style 23  = YYYY-MM-DD
-- Style 103 = DD/MM/YYYY
WITH parsed_dates AS (
    SELECT
        transaction_date,
        COALESCE(
            TRY_CONVERT(
                DATE,
                NULLIF(LTRIM(RTRIM(transaction_date)), ''),
                23
            ),
            TRY_CONVERT(
                DATE,
                NULLIF(LTRIM(RTRIM(transaction_date)), ''),
                103
            )
        ) AS parsed_date
    FROM stg.transactions
)
SELECT
    SUM(
        CASE
            WHEN transaction_date LIKE '%/%' THEN 1
            ELSE 0
        END
    ) AS day_month_year_rows,

    SUM(
        CASE
            WHEN parsed_date IS NULL THEN 1
            ELSE 0
        END
    ) AS invalid_date_rows
FROM parsed_dates;

-- Verified result:
-- 6 rows use DD/MM/YYYY.
-- Most transaction dates use YYYY-MM-DD.
GO