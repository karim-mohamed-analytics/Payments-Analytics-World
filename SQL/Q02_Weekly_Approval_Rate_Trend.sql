
/*
Project: Payments Analytics World
Query ID: Q02
Query Name: Weekly Approval Rate Trend
Category: Failure Isolation
Tool: SQL Server 2022 (T-SQL)

BUSINESS QUESTION
-----------------
How does the weekly payment approval rate change over time?

BUSINESS OBJECTIVE
------------------
Identify weeks with noticeable changes in approval performance
and narrow down the period for further investigation.

METRICS
-------
1. Total Attempts
2. Approved Attempts
3. Declined Attempts
4. Approval Rate (%)
5. Decline Rate (%)

CALCULATION
-----------
Approval Rate = Approved Attempts / Total Attempts * 100
Decline Rate  = Declined Attempts / Total Attempts * 100

GRAIN
-----
One row per calendar week, starting Monday.

DATA SOURCE
-----------
dbo.FactTransactions

NOTES
-----
- Measures payment attempts, including retries.
- FirstTransactionDate and LastTransactionDate show the first
  and last transaction dates observed within each week.
- The first and last weeks may be partial weeks.
- Weekly comparisons should account for differences in
  observation periods and transaction volumes.
*/

SET DATEFIRST 1; -- Monday is the first day of the week

WITH WeeklyData AS
                   (
                       SELECT
                              DATETRUNC(WEEK, TransactionDateTime) AS WeekStartDate,
                               CAST(TransactionDateTime AS DATE) AS TransactionDate,
                               TransactionStatus
                       FROM dbo.FactTransactions
                    )

SELECT
    WeekStartDate,
    MIN(TransactionDate) AS FirstTransactionDate,
    MAX(TransactionDate) AS LastTransactionDate,
    COUNT_BIG(*) AS TotalAttempts,
    SUM( CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0  END ) AS ApprovedAttempts,
    SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0 END ) AS DeclinedAttempts,
    CAST(100.0 * SUM(CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                      / COUNT_BIG(*) AS DECIMAL(6, 2) ) AS ApprovalRate,

    CAST( 100.0 * SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0 END)
                       / COUNT_BIG(*) AS DECIMAL(6, 2) ) AS DeclineRate

FROM WeeklyData
GROUP BY WeekStartDate
ORDER BY WeekStartDate;
