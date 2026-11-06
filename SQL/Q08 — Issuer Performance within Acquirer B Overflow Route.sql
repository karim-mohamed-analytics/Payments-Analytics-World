/*
Project: Payments Analytics World
Query ID: Q08
Query Name: Issuer Analysis within Acquirer B Overflow Route
Category: Approval Rate Investigation
Tool: SQL Server

Business Question:
Is the approval rate deterioration within Acquirer B Overflow Route
associated with specific Issuers or a change in Issuer transaction mix?

Business Objective:
Distinguish Issuer-level performance deterioration
from changes in Issuer distribution within the route.

Metrics:
- Total Attempts
- Approved Attempts
- Declined Attempts
- Approval Rate
- Issuer Mix
- Approval Rate Change (pp)
- Issuer Mix Change (pp)

Grain: Period x Issuer
Data Source: FactTransactions, DimAcquirer, DimRoute, DimIssuer

Notes:
- Before: Jan 6 - Apr 19, 2025
- After: Apr 20 - Jul 6, 2025
- Acquirer B Overflow Route only.
- Retries are included.
*/

WITH IssuerPerformance AS
                        (
                          SELECT
                                 CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before' ELSE 'After' END AS Period,
                                 COALESCE(i.IssuerName, 'Unknown Issuer') AS IssuerName,
                                 COUNT_BIG(*) AS TotalAttempts,
                                 SUM(CASE WHEN t.TransactionStatus = 'Approved' THEN 1 ELSE 0  END) AS ApprovedAttempts,
                                 SUM(CASE WHEN t.TransactionStatus = 'Declined' THEN 1 ELSE 0 END) AS DeclinedAttempts

                          FROM dbo.FactTransactions t  INNER JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID
                                                       INNER JOIN dbo.DimRoute r ON t.RouteID = r.RouteID
                                                       LEFT JOIN dbo.DimIssuer i ON t.IssuerID = i.IssuerID

                          WHERE t.TransactionDateTime >= '2025-01-06'  AND t.TransactionDateTime <  '2025-07-07'
                                AND a.AcquirerName = 'Acquirer B'
                                AND r.RouteName = 'Acquirer B Overflow Route'

                        GROUP BY
                                 CASE WHEN t.TransactionDateTime < '2025-04-20'THEN 'Before' ELSE 'After' END,
                                  COALESCE(i.IssuerName, 'Unknown Issuer')
                       ),

PeriodTotals AS
                (
                 SELECT
                      Period,
                      SUM(TotalAttempts) AS PeriodTotalAttempts
                 FROM IssuerPerformance
                GROUP BY Period
                ),

Metrics AS
            (
               SELECT
                  ip.Period,
                  ip.IssuerName,
                  ip.TotalAttempts,
                  ip.ApprovedAttempts,
                  ip.DeclinedAttempts,
                  100.0 * ip.ApprovedAttempts / NULLIF(ip.TotalAttempts, 0) AS ApprovalRate,
                  100.0 * ip.TotalAttempts / NULLIF(pt.PeriodTotalAttempts, 0) AS IssuerMix
               FROM IssuerPerformance ip INNER JOIN PeriodTotals pt  ON ip.Period = pt.Period
            )

SELECT
    b.IssuerName,
    b.TotalAttempts AS Before_Attempts,
    a.TotalAttempts AS After_Attempts,
    b.DeclinedAttempts AS Before_Declined,
    a.DeclinedAttempts AS After_Declined,
    CAST(b.ApprovalRate AS DECIMAL(10,2)) AS Before_ApprovalRate,
    CAST(a.ApprovalRate AS DECIMAL(10,2)) AS After_ApprovalRate,
    CAST( a.ApprovalRate - b.ApprovalRate AS DECIMAL(10,2)) AS ApprovalRate_Change_pp,
    CAST(b.IssuerMix AS DECIMAL(10,2)) AS Before_Mix,
    CAST(a.IssuerMix AS DECIMAL(10,2)) AS After_Mix,
    CAST( a.IssuerMix - b.IssuerMix AS DECIMAL(10,2) ) AS IssuerMix_Change_pp

FROM Metrics b INNER JOIN Metrics a ON b.IssuerName = a.IssuerName
   AND b.Period = 'Before' AND a.Period = 'After'
ORDER BY
    ApprovalRate_Change_pp ASC;