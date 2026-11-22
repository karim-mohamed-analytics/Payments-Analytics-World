
/*
-- Q03: Daily Approval Rate Trend
-- Question: on which date did the approval rate start to fall?
-- Period: Jan 6 to Jul 6, 2025. Retries are included.
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