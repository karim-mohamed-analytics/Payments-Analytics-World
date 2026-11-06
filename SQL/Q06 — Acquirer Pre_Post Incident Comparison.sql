/*
Project: Payments Analytics World
Query ID: Q06
Query Name: Acquirer Pre/Post Incident Comparison
Category: Approval Rate Investigation
Tool: SQL Server

Business Question:
Did any Acquirer experience significant performance deterioration
after April 20, 2025?

Business Objective:
Identify whether Acquirer B was a major contributor
to the overall Approval Rate decline.

Metrics:
- Before / After Total Attempts
- Before / After Approved Attempts
- Before / After Declined Attempts
- Before / After Approval Rate
- Before / After Transaction Mix
- Before / After Share of Total Declines
- Approval Rate Change (pp)
- Transaction Mix Change (pp)

Grain: Acquirer
Data Source: FactTransactions, DimAcquirer

Notes:
- Before: Jan 6 - Apr 19, 2025
- After: Apr 20 - Jul 6, 2025
- Retries are included.
*/

WITH AcquirerPerformance AS
                         (
                           SELECT
                             CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before' ELSE 'After'END AS Period,
                             COALESCE(a.AcquirerName, 'Unknown Acquirer') AS AcquirerName,
                             COUNT_BIG(*) AS TotalAttempts,
                             SUM(CASE WHEN t.TransactionStatus = 'Approved' THEN 1 ELSE 0 END) AS ApprovedAttempts,
                             SUM(CASE WHEN t.TransactionStatus = 'Declined' THEN 1  ELSE 0 END) AS DeclinedAttempts

                          FROM dbo.FactTransactions t LEFT JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID
                          WHERE t.TransactionDateTime >= '2025-01-06' AND t.TransactionDateTime <  '2025-07-07'
                          GROUP BY
                                   CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before' ELSE 'After' END,
                                     COALESCE(a.AcquirerName, 'Unknown Acquirer')
                        ),

PeriodTotals AS(
                 SELECT
                     Period,
                     SUM(TotalAttempts) AS PeriodTotalAttempts,
                     SUM(DeclinedAttempts) AS PeriodTotalDeclines
                     FROM AcquirerPerformance
                    GROUP BY Period
              ),

Metrics AS
             (
               SELECT
                    ap.Period,
                    ap.AcquirerName,
                    ap.TotalAttempts,
                    ap.ApprovedAttempts,
                    ap.DeclinedAttempts,
                    100.0 * ap.ApprovedAttempts / NULLIF(ap.TotalAttempts, 0) AS ApprovalRate,
                    100.0 * ap.TotalAttempts / NULLIF(pt.PeriodTotalAttempts, 0) AS TransactionMix,
                    100.0 * ap.DeclinedAttempts / NULLIF(pt.PeriodTotalDeclines, 0) AS ShareOfTotalDeclines
              FROM AcquirerPerformance ap  INNER JOIN PeriodTotals pt ON ap.Period = pt.Period
             )

SELECT
    b.AcquirerName,
    b.TotalAttempts AS Before_Attempts,
    a.TotalAttempts AS After_Attempts,
    b.DeclinedAttempts AS Before_Declined,
    a.DeclinedAttempts AS After_Declined,
    CAST(b.ApprovalRate AS DECIMAL(10,2)) AS Before_ApprovalRate,
    CAST(a.ApprovalRate AS DECIMAL(10,2)) AS After_ApprovalRate,
    CAST( a.ApprovalRate - b.ApprovalRate AS DECIMAL(10,2) ) AS ApprovalRate_Change_pp,
    CAST(b.TransactionMix AS DECIMAL(10,2)) AS Before_Mix,
    CAST(a.TransactionMix AS DECIMAL(10,2)) AS After_Mix,
    CAST( a.TransactionMix - b.TransactionMix AS DECIMAL(10,2) ) AS TransactionMix_Change_pp,
    CAST(b.ShareOfTotalDeclines AS DECIMAL(10,2)) AS Before_DeclineShare,
    CAST(a.ShareOfTotalDeclines AS DECIMAL(10,2)) AS After_DeclineShare

     FROM Metrics b INNER JOIN Metrics a ON b.AcquirerName = a.AcquirerName AND b.Period = 'Before' AND a.Period = 'After'
     ORDER BY
    ApprovalRate_Change_pp ASC;