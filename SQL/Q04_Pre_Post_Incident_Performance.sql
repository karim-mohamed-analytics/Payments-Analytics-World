/*
Project: Payments Analytics World
Query ID: Q04
Query Name: Pre vs Post Incident Performance
Category: Failure Isolation
Tool: SQL Server 2022 (T-SQL)

BUSINESS QUESTION
-----------------
How did payment performance change before and after
the suspected incident start date of 2025-04-20?

BUSINESS OBJECTIVE
------------------
Measure the overall performance deterioration across
the entire available dataset.

METRICS
-------
1. Total Attempts
2. Approved Attempts
3. Declined Attempts
4. Approval Rate (%)
5. Decline Rate (%)
6. Average Daily Attempts
7. Average Daily Declined Attempts

GRAIN
-----
One row per comparison period.

DATA SOURCE
-----------
dbo.FactTransactions

COMPARISON PERIODS
------------------
Before: 2025-01-06 through 2025-04-19.
After:  2025-04-20 through 2025-07-06.

NOTES
-----
- Entire available dataset is included.
- Periods have different durations.
- Daily averages are included to account for duration differences.
- Retries are included.
- Comparison does not establish causation.
*/

WITH PeriodData AS (
                     SELECT
                            CASE WHEN TransactionDateTime >= '20250106' AND TransactionDateTime < '20250420'THEN 'Before Incident'
                                 WHEN TransactionDateTime >= '20250420' AND TransactionDateTime < '20250707'THEN 'After Incident'  END AS Period,
                           CAST(TransactionDateTime AS DATE) AS TransactionDate,
                             TransactionStatus
                    FROM dbo.FactTransactions
                     WHERE  TransactionDateTime >= '20250106' AND TransactionDateTime < '20250707'
                     ),

PeriodSummary AS
                 (
                   SELECT
                          Period,
                          COUNT_BIG(*) AS TotalAttempts,
                          SUM( CASE WHEN TransactionStatus = 'Approved' THEN 1 ELSE 0 END) AS ApprovedAttempts,
                          SUM( CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0 END) AS DeclinedAttempts,
                          COUNT(DISTINCT TransactionDate) AS ActiveDays

                   FROM PeriodData
                   GROUP BY Period
                  )
SELECT
    Period,
    ActiveDays,
    TotalAttempts,
    ApprovedAttempts,
    DeclinedAttempts,
    CAST( 100.0 * ApprovedAttempts / NULLIF(TotalAttempts, 0) AS DECIMAL(6,2) ) AS ApprovalRate,
    CAST( 100.0 * DeclinedAttempts / NULLIF(TotalAttempts, 0) AS DECIMAL(6,2) ) AS DeclineRate,
    CAST( 1.0 * TotalAttempts / NULLIF(ActiveDays, 0) AS DECIMAL(10,2) ) AS AverageDailyAttempts,
    CAST( 1.0 * DeclinedAttempts / NULLIF(ActiveDays, 0) AS DECIMAL(10,2) ) AS AverageDailyDeclinedAttempts

FROM PeriodSummary
ORDER BY
    CASE WHEN Period = 'Before Incident' THEN 1 WHEN Period = 'After Incident' THEN 2 END;