
/*
Project: Payments Analytics World
Query ID: Q01
Query Name: Monthly Approval Rate Trend
Category: Data Profiling
Tool: SQL Server 2022 (T-SQL)

BUSINESS QUESTION
-----------------
How does the monthly payment approval rate change over time?

BUSINESS OBJECTIVE
------------------
Establish a monthly performance baseline and identify periods
of declining payment approval performance.

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
One row per calendar month.

DATA SOURCE
-----------
dbo.FactTransactions

NOTES
-----
- Measures payment attempts, including retries.
- July 2025 contains data only through July 6.
- July is a partial month and should not be compared directly
  with complete months without accounting for the difference
  in observation period.
*/

SELECT
        YEAR(TransactionDateTime)as tnx_year , 
        MONTH(TransactionDateTime) as tnx_month , 
        COUNT_BIG(*) AS TotalAttempts,
      SUM( CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END ) AS ApprovedAttempts,
      SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0  END ) AS DeclinedAttempts,
      CAST( 100.0 * SUM( CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                        / COUNT_BIG(*) AS DECIMAL(6, 2) ) AS ApprovalRate,

           CAST( 100.0 * SUM(CASE  WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0  END)
                        / COUNT_BIG(*) AS DECIMAL(6, 2) ) AS DeclineRate

FROM dbo.FactTransactions
GROUP BY
        YEAR(TransactionDateTime),
        MONTH(TransactionDateTime)
        
ORDER BY
    tnx_month;