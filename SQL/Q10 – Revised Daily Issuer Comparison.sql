/*
============================================================
Project: Payments Analytics World
Query ID: Q10
Query Name: Daily Issuer Performance Comparison
Category: Approval Rate Investigation
Tool: SQL Server 2022 - SSMS

Business Question:
Did the three identified Issuers experience an Approval
Rate deterioration at approximately the same time?

Business Objective:
Compare the daily performance of the three Issuers
side by side to identify whether their deterioration
was synchronized.

Metrics:
1. Daily Attempts per Issuer
2. Daily Approved Attempts per Issuer
3. Daily Approval Rate per Issuer

Grain:
One row per day.

Data Source:
- dbo.FactTransactions
- dbo.DimAcquirer
- dbo.DimRoute
- dbo.DimIssuer

Date Range:
January 6, 2025 - July 6, 2025

Pre-Incident:
January 6 - April 19, 2025

Post-Incident:
April 20 - July 6, 2025

Filters:
- Acquirer B
- Acquirer B Overflow Route
- Tier3 Bank 3
- Tier2 Bank 3
- Tier1 Bank 1

Notes:
- Retries are included.
- Each Issuer appears in separate columns.
- Approval Rate is calculated independently
  for each Issuer.
- This query identifies timing patterns, not causality.
============================================================
*/

-- Step 1: Prepare filtered transaction data
WITH FilteredTransactions AS
                              (
                              SELECT
                                 CAST(t.TransactionDateTime AS DATE) AS TransactionDate,
                                 i.IssuerName,
                                 t.TransactionStatus
                             FROM dbo.FactTransactions t INNER JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID
                                                         INNER JOIN dbo.DimRoute r  ON t.RouteID = r.RouteID
                                                         LEFT JOIN dbo.DimIssuer i ON t.IssuerID = i.IssuerID
                            WHERE t.TransactionDateTime >= '2025-01-06'
                               AND t.TransactionDateTime < '2025-07-07'
                               AND a.AcquirerName = 'Acquirer B'
                               AND r.RouteName = 'Acquirer B Overflow Route'
                               AND i.IssuerName IN ( 'Tier3 Bank 3','Tier2 Bank 3','Tier1 Bank 1' )
                             )


SELECT
    TransactionDate,
    SUM(CASE WHEN IssuerName = 'Tier3 Bank 3' THEN 1 ELSE 0 END) AS Tier3_Attempts,
    SUM(CASE WHEN IssuerName = 'Tier3 Bank 3' AND TransactionStatus = 'Approved' THEN 1  ELSE 0 END) AS Tier3_Approved,
    CAST( 100.0 * SUM(CASE WHEN IssuerName = 'Tier3 Bank 3'  AND TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                                   / NULLIF(SUM(CASE WHEN IssuerName = 'Tier3 Bank 3' THEN 1 ELSE 0 END), 0) AS DECIMAL(10,2)  ) AS Tier3_ApprovalRate,
    
    SUM(CASE WHEN IssuerName = 'Tier2 Bank 3' THEN 1 ELSE 0 END) AS Tier2_Attempts,
    SUM(CASE WHEN IssuerName = 'Tier2 Bank 3'  AND TransactionStatus = 'Approved' THEN 1 ELSE 0 END) AS Tier2_Approved,
    CAST( 100.0 * SUM(CASE WHEN IssuerName = 'Tier2 Bank 3'  AND TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                                  / NULLIF(SUM(CASE WHEN IssuerName = 'Tier2 Bank 3' THEN 1 ELSE 0 END), 0)AS DECIMAL(10,2)) AS Tier2_ApprovalRate,

    SUM(CASE  WHEN IssuerName = 'Tier1 Bank 1' THEN 1  ELSE 0 END) AS Tier1_Attempts,
    SUM(CASE WHEN IssuerName = 'Tier1 Bank 1' AND TransactionStatus = 'Approved' THEN 1 ELSE 0 END) AS Tier1_Approved,
    CAST( 100.0 * SUM(CASE WHEN IssuerName = 'Tier1 Bank 1' AND TransactionStatus = 'Approved' THEN 1 ELSE 0 END)
                                 / NULLIF(SUM(CASE WHEN IssuerName = 'Tier1 Bank 1' THEN 1 ELSE 0 END), 0) AS DECIMAL(10,2)) AS Tier1_ApprovalRate

FROM FilteredTransactions
GROUP BY
    TransactionDate
ORDER BY
    TransactionDate;