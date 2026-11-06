/*
Project: Payments Analytics World
Query ID: Q09
Query Name: Daily Approval Rate Trend - Tier3 Bank 3
Category: Approval Rate Investigation
Tool: SQL Server

Business Question:
Did Tier3 Bank 3 experience a sudden Approval Rate deterioration
around April 20, 2025, or was the decline already happening?

Business Objective:
Determine the timing and pattern of performance deterioration
for Tier3 Bank 3 within Acquirer B Overflow Route.

Metrics:
- Total Attempts
- Approved Attempts
- Declined Attempts
- Daily Approval Rate

Grain: Transaction Date x Issuer
Data Source: FactTransactions, DimAcquirer, DimRoute, DimIssuer

Notes:
- Analysis period: Jan 6 - Jul 6, 2025
- Acquirer B Overflow Route only.
- Tier3 Bank 3 only.
- Retries are included.
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