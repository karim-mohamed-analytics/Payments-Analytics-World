/*
Project: Payments Analytics World
Query ID: Q07
Query Name: Acquirer B Route Performance Analysis
Category: Approval Rate Investigation
Tool: SQL Server

Business Question:
Is Acquirer B's performance deterioration concentrated
in a specific route or distributed across its routes?

Business Objective:
Identify the route most strongly associated with
Acquirer B's post-incident performance deterioration.

Metrics:
- Total Attempts
- Approved Attempts
- Declined Attempts
- Approval Rate
- Transaction Mix within Acquirer B
- Share of Acquirer B Declines

Grain: Period x Route
Data Source: FactTransactions, DimAcquirer, DimRoute

Notes:
- Before: Jan 6 - Apr 19, 2025
- After: Apr 20 - Jul 6, 2025
- Only Acquirer B transactions are included.
- Retries are included.
*/

WITH RoutePerformance AS
                       (
                         SELECT
                             CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before' ELSE 'After' END AS Period,
                             COALESCE(r.RouteName, 'Unknown Route') AS RouteName,
                             COUNT_BIG(*) AS TotalAttempts,
                             SUM(CASE WHEN t.TransactionStatus = 'Approved' THEN 1 ELSE 0 END) AS ApprovedAttempts,
                             SUM(CASE WHEN t.TransactionStatus = 'Declined' THEN 1 ELSE 0 END) AS DeclinedAttempts

                        FROM dbo.FactTransactions t INNER JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID LEFT JOIN dbo.DimRoute r ON t.RouteID = r.RouteID
                        WHERE t.TransactionDateTime >= '2025-01-06'  AND t.TransactionDateTime <  '2025-07-07' AND a.AcquirerName = 'Acquirer B'
                       GROUP BY
                                CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before' ELSE 'After' END, COALESCE(r.RouteName, 'Unknown Route')
                       ),

PeriodTotals AS
                (
                 SELECT
                    Period,
                    SUM(TotalAttempts) AS PeriodTotalAttempts,
                     SUM(DeclinedAttempts) AS PeriodTotalDeclines
                FROM RoutePerformance
                GROUP BY Period
                ),

Metrics AS
           (
                SELECT
                    rp.Period,
                    rp.RouteName,
                    rp.TotalAttempts,
                    rp.ApprovedAttempts,
                    rp.DeclinedAttempts,
                    100.0 * rp.ApprovedAttempts / NULLIF(rp.TotalAttempts, 0) AS ApprovalRate,
                    100.0 * rp.TotalAttempts / NULLIF(pt.PeriodTotalAttempts, 0) AS TransactionMix,
                    100.0 * rp.DeclinedAttempts /  NULLIF(pt.PeriodTotalDeclines, 0) AS ShareOfAcquirerBDeclines

               FROM RoutePerformance rp INNER JOIN PeriodTotals pt ON rp.Period = pt.Period
           )

SELECT
    b.RouteName,
    b.TotalAttempts AS Before_Attempts,
    a.TotalAttempts AS After_Attempts,
    b.DeclinedAttempts AS Before_Declined,
    a.DeclinedAttempts AS After_Declined,
    CAST(b.ApprovalRate AS DECIMAL(10,2)) AS Before_ApprovalRate,
    CAST(a.ApprovalRate AS DECIMAL(10,2)) AS After_ApprovalRate,
    CAST( a.ApprovalRate - b.ApprovalRate AS DECIMAL(10,2)) AS ApprovalRate_Change_pp,
    CAST(b.TransactionMix AS DECIMAL(10,2)) AS Before_Mix,
    CAST(a.TransactionMix AS DECIMAL(10,2)) AS After_Mix,
    CAST( a.TransactionMix - b.TransactionMix AS DECIMAL(10,2) ) AS TransactionMix_Change_pp,
    CAST( b.ShareOfAcquirerBDeclines AS DECIMAL(10,2)) AS Before_DeclineShare,
    CAST( a.ShareOfAcquirerBDeclines AS DECIMAL(10,2) ) AS After_DeclineShare

FROM Metrics b INNER JOIN Metrics a ON b.RouteName = a.RouteName AND b.Period = 'Before' AND a.Period = 'After'
ORDER BY
    ApprovalRate_Change_pp ASC;