USE retail_banking_dw;
GO

/* ============================================================
   11_create_reporting_dimensions.sql

   Purpose:
   Create shared reporting dimensions used by the Power BI
   semantic model.

   dim_city acts as a common filter dimension for:
   - mart.customer_transaction_summary
   - mart.monthly_transaction_summary
   ============================================================ */


/* ------------------------------------------------------------
   1. Create City Dimension
   ------------------------------------------------------------ */

IF OBJECT_ID(N'mart.dim_city', N'U') IS NULL
BEGIN
    CREATE TABLE mart.dim_city (
        city NVARCHAR(100) NOT NULL,

        CONSTRAINT PK_dim_city
            PRIMARY KEY (city)
    );
END;
GO


/* ------------------------------------------------------------
   2. Refresh City Dimension
   ------------------------------------------------------------ */

DELETE FROM mart.dim_city;
GO

INSERT INTO mart.dim_city (city)
SELECT DISTINCT city
FROM (
    SELECT city
    FROM mart.customer_transaction_summary

    UNION

    SELECT city
    FROM mart.monthly_transaction_summary
) AS cities
WHERE city IS NOT NULL
  AND LTRIM(RTRIM(city)) <> '';
GO


/* ------------------------------------------------------------
   3. Validation
   ------------------------------------------------------------ */

SELECT
    city
FROM mart.dim_city
ORDER BY city;
GO