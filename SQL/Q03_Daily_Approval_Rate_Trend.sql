
/*
Project: Payments Analytics World
Query ID: Q03
Query Name: Daily Approval Rate Trend
Category: Failure Isolation
Tool: SQL Server 2022 (T-SQL)

BUSINESS QUESTION
-----------------
On which date did the payment approval rate begin to decline?

BUSINESS OBJECTIVE
------------------
Identify the timing and severity of the daily approval rate decline
around the period of the weekly performance drop.

METRICS
-------
1. Total Attempts
2. Approved Attempts
3. Declined Attempts
4. Approval Rate (%)
5. Decline Rate (%)

GRAIN
-----
One row per calendar date.

DATA SOURCE
-----------
dbo.FactTransactions

NOTES
-----
- Includes retries.
- The date range is limited to 2025-04-14 through 2025-05-04.
*/

SELECT
    CAST(TransactionDateTime AS DATE) AS TransactionDate,
    COUNT_BIG(*) AS TotalAttempts,
    SUM( CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END ) AS ApprovedAttempts,
    SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0 END ) AS DeclinedAttempts,
    CAST( 100.0 * SUM(CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                      / COUNT_BIG(*) AS DECIMAL(6, 2) ) AS ApprovalRate,

    CAST( 100.0 * SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0 END)
                      / COUNT_BIG(*)AS DECIMAL(6, 2) ) AS DeclineRate

FROM dbo.FactTransactions
WHERE TransactionDateTime >= '20250106' AND TransactionDateTime <  '20250707'
GROUP BY
    CAST(TransactionDateTime AS DATE)
ORDER BY
    TransactionDate;
