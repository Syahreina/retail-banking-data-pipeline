# Data Quality Findings

This is a personal learning project using synthetic retail banking data. The findings below were verified during a local SQL Server run before cleansing. SQL profiling checks are available in [`04_data_quality_profiling.sql`](../sql/04_data_quality_profiling.sql).

## Customers

- One duplicate customer row was identified. During the dimension load, one row is retained per `customer_id`.

- `city` contains inconsistent casing and whitespace. Values are trimmed and converted to uppercase before loading into `dw.dim_customer`.

- Because the CSV files use CRLF line endings while the bulk load uses LF (`0x0a`) as the row terminator, the final `registration_date` field can retain `CHAR(13)`. This character is removed before date conversion.

- Registration dates are valid after cleanup and conversion to `DATE`.

## Accounts

- Four rows have a missing `customer_id`. These accounts remain in `dw.dim_account`, with `customer_key` stored as `NULL`.

- No duplicate `account_id` values were found.

- No nonblank orphan `customer_id` values were found against the customer master.

- The final `status` field can retain `CHAR(13)` after import. The value is cleaned, trimmed, and converted to uppercase.

- Valid normalized account statuses are `ACTIVE` and `CLOSED`.

- Opening dates convert successfully to `DATE`.

## Transactions

- Five duplicate `transaction_id` values were identified. Only one row per transaction ID is retained during the fact load.

- Eight rows have a missing `account_id`.

- Ten rows contain an `account_id` that is not present in the account master. These rows cannot be matched to `dw.dim_account` and are excluded from the fact table.

- Eight rows have a missing amount.

- Ten rows have a negative amount. These rows are excluded from the fact table.

- Ten rows contain the invalid transaction type `UNKNOWN`.

- Five additional rows contain extra whitespace around otherwise valid transaction types. Transaction types are trimmed and converted to uppercase before validation.

- Six transaction dates use `DD/MM/YYYY`, while most use `YYYY-MM-DD`. Both formats are parsed and standardized into the SQL Server `DATE` type.

- The final `amount` field can retain `CHAR(13)` after import. The character is removed before conversion using `TRY_CONVERT(DECIMAL(18,2), ...)`.

## Final Warehouse Result

After deduplication, validation, cleansing, and referential checks, the current dataset produces:

- `1,000` rows in `dw.dim_customer`
- `1,800` rows in `dw.dim_account`
- `19,954` rows in `dw.fact_transaction`
- `1,000` rows in `mart.customer_transaction_summary`

These counts were verified during local execution in SQL Server. The repository contains the scripts and synthetic source files, but does not store the executed database itself.