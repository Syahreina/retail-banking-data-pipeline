USE retail_banking_dw;
GO

-- A. LOAD DIM CUSTOMER ---------------------------------------------------
WITH cleaned_customer AS (
    SELECT LTRIM(RTRIM(customer_id)) AS customer_id,
           LTRIM(RTRIM(customer_name)) AS customer_name,
           UPPER(LTRIM(RTRIM(city))) AS city,
           TRY_CONVERT(DATE,
               LTRIM(RTRIM(REPLACE(registration_date, CHAR(13), ''))), 23
           ) AS registration_date
    FROM stg.customers
), ranked_customer AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY customer_id
           ) AS rn
    FROM cleaned_customer
)
INSERT INTO dw.dim_customer
    (customer_id, customer_name, city, registration_date)
SELECT customer_id, customer_name, city, registration_date
FROM ranked_customer
WHERE rn = 1
  AND NOT EXISTS (
      SELECT 1
      FROM dw.dim_customer AS existing
      WHERE existing.customer_id = ranked_customer.customer_id
  );

-- Expected: 1,001 staging rows become 1,000 unique dimension rows.
SELECT COUNT(*) AS customer_rows FROM dw.dim_customer;
SELECT COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT customer_id FROM dw.dim_customer
    GROUP BY customer_id HAVING COUNT(*) > 1
) AS duplicates;

-- B. LOAD DIM ACCOUNT ----------------------------------------------------
-- Keep accounts with missing customer_id; their customer_key stays NULL.
INSERT INTO dw.dim_account
    (account_id, customer_key, account_type, opening_date, status)
SELECT LTRIM(RTRIM(a.account_id)),
       c.customer_key,
       UPPER(LTRIM(RTRIM(a.account_type))),
       TRY_CONVERT(DATE, LTRIM(RTRIM(a.opening_date)), 23),
       UPPER(LTRIM(RTRIM(REPLACE(a.status, CHAR(13), ''))))
FROM stg.accounts AS a
LEFT JOIN dw.dim_customer AS c
    ON LTRIM(RTRIM(a.customer_id)) = c.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.dim_account AS existing
    WHERE existing.account_id = LTRIM(RTRIM(a.account_id))
);

-- Expected: 1,800 accounts, including four without a customer_key.
SELECT COUNT(*) AS account_rows,
       SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS accounts_without_customer
FROM dw.dim_account;
GO
