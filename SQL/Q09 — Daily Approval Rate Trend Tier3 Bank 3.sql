/*
-- Q09: Daily Approval Rate Trend - Tier3 Bank 3
-- Question: did Tier3 Bank 3 drop suddenly around April 20,
-- or was it already falling before?
-- Period: Jan 6 to Jul 6, 2025. Retries are included.
-- Only Acquirer B Overflow Route and Tier3 Bank 3.
*/

SELECT
    CAST(t.TransactionDateTime AS DATE) AS TransactionDate,
    i.IssuerName AS IssuerName,
    COUNT_BIG(*) AS TotalAttempts,
    SUM( CASE  WHEN t.TransactionStatus = 'Approved' THEN 1 ELSE 0 END ) AS ApprovedAttempts,
    SUM( CASE WHEN t.TransactionStatus = 'Declined' THEN 1 ELSE 0 END ) AS DeclinedAttempts,
    CAST( 100.0 * SUM( CASE WHEN t.TransactionStatus = 'Approved' THEN 1 ELSE 0 END ) / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,2) ) AS ApprovalRate

FROM dbo.FactTransactions t INNER JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID
                            INNER JOIN dbo.DimRoute r ON t.RouteID = r.RouteID
                            INNER JOIN dbo.DimIssuer i ON t.IssuerID = i.IssuerID
WHERE t.TransactionDateTime >= '2025-01-06'
  AND t.TransactionDateTime <  '2025-07-07'
  AND a.AcquirerName = 'Acquirer B'
  AND r.RouteName = 'Acquirer B Overflow Route'
  AND i.IssuerName = 'Tier3 Bank 3'
GROUP BY
    CAST(t.TransactionDateTime AS DATE),
    i.IssuerName

ORDER BY
    TransactionDate;