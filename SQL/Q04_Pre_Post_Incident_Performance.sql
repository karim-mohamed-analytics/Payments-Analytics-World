/*
-- Q04: Pre vs Post Incident Performance
-- Question: how did performance change before and after April 20, 2025?
-- Before: Jan 6 to Apr 19 (104 days). After: Apr 20 to Jul 6 (78 days).
-- The periods have different lengths, so daily averages are included.
-- Retries are included.
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