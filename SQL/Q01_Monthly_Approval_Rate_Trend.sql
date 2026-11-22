
/*
-- Q01: Monthly Approval Rate Trend
-- Question: how does the approval rate change month by month?
-- Period: the whole dataset (Jan 6 to Jul 6, 2025). Retries are included.
-- July is a partial month (data only until July 6).
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