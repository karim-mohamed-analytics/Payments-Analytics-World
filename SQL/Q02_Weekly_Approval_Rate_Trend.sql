
/*
-- Q02: Weekly Approval Rate Trend
-- Question: which weeks show a change in the approval rate?
-- Period: Jan 6 to Jul 6, 2025. Retries are included.
-- Weeks start on Monday. The week of April 14 also includes April 20.
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