/*
============================================================
Project: Payments Analytics World
Query ID: Q11
Query Name: Pre-Post Incident Decline Category Analysis
Category: Approval Rate Investigation
Tool: SQL Server 2022 - SSMS

Business Question:
Did the Approval Rate deterioration after April 20, 2025
coincide with an increase in Technical Declines, or was
the deterioration mainly associated with other decline
categories?

Business Objective:
Compare decline categories before and after the incident
to determine whether Technical Errors became a more
significant contributor to the deterioration.

Metrics:
1. Total Attempts
2. Total Declines
3. Approval Rate
4. Technical Declines
5. Technical Decline Rate
6. Customer Declines
7. Customer Decline Rate
8. Authentication Declines
9. Authentication Decline Rate
10. Risk Declines
11. Other / Unknown Declines

Grain:
One row per Incident Period.

Data Sources:
- dbo.FactTransactions
- dbo.DimAcquirer
- dbo.DimRoute
- dbo.DimDeclineReason

Date Range:
January 6, 2025 - July 6, 2025

Pre-Incident:
January 6 - April 19, 2025

Post-Incident:
April 20 - July 6, 2025

Filters:
- Acquirer B
- Acquirer B Overflow Route

Notes:
- Retries are included.
- All transaction attempts are included in the
  denominator of category decline rates.
- Decline categories are taken from DimDeclineReason.
- LEFT JOIN is used to preserve all transaction attempts.
- This analysis identifies associations, not causality.
============================================================
*/

-- Step 1: Prepare transactions and classify incident period
WITH TransactionData AS
                        (
                           SELECT
                              CASE WHEN t.TransactionDateTime < '2025-04-20' THEN 'Before Incident' ELSE 'After Incident'  END AS IncidentPeriod,
                              t.TransactionStatus,
                              COALESCE(d.DeclineCategory, 'Unknown') AS DeclineCategory

                          FROM dbo.FactTransactions t INNER JOIN dbo.DimAcquirer a ON t.AcquirerID = a.AcquirerID
                                                      INNER JOIN dbo.DimRoute r ON t.RouteID = r.RouteID
                                                      LEFT JOIN dbo.DimDeclineReason d ON t.DeclineReasonID = d.DeclineReasonID
                          WHERE  t.TransactionDateTime >= '2025-01-06'  AND t.TransactionDateTime < '2025-07-07'
                                                                        AND a.AcquirerName = 'Acquirer B'
                                                                        AND r.RouteName = 'Acquirer B Overflow Route'
                         ),

CategoryAnalysis AS
                    (
                      SELECT
                         IncidentPeriod,
                         COUNT_BIG(*) AS TotalAttempts,
                         SUM(CASE  WHEN TransactionStatus = 'Approved' THEN 1  ELSE 0 END) AS ApprovedAttempts,
                         SUM(CASE WHEN TransactionStatus = 'Declined' THEN 1 ELSE 0  END) AS TotalDeclines,
                         SUM(CASE  WHEN TransactionStatus = 'Declined'  AND DeclineCategory = 'Technical' THEN 1  ELSE 0  END) AS TechnicalDeclines,
                         SUM(CASE  WHEN TransactionStatus = 'Declined'  AND DeclineCategory = 'Customer' THEN 1  ELSE 0  END) AS CustomerDeclines,
                         SUM(CASE  WHEN TransactionStatus = 'Declined'  AND DeclineCategory = 'Authentication' THEN 1   ELSE 0   END) AS AuthenticationDeclines,
                         SUM(CASE  WHEN TransactionStatus = 'Declined'  AND DeclineCategory = 'Risk' THEN 1  ELSE 0  END) AS RiskDeclines, 
                         SUM(CASE  WHEN TransactionStatus = 'Declined'  AND DeclineCategory NOT IN  ('Technical', 'Customer', 'Authentication', 'Risk')
                                               THEN 1 ELSE 0 END) AS OtherUnknownDeclines

                     FROM TransactionData
                     GROUP BY IncidentPeriod
                    )

SELECT
    IncidentPeriod,
    TotalAttempts,
    ApprovedAttempts,
    TotalDeclines,
    CAST( 100.0 * ApprovedAttempts  / NULLIF(TotalAttempts, 0) AS DECIMAL(10,2)  ) AS ApprovalRate,
    TechnicalDeclines,
    CAST(  100.0 * TechnicalDeclines  / NULLIF(TotalAttempts, 0)   AS DECIMAL(10,2)  ) AS TechnicalDeclineRate, 
    CustomerDeclines,
    CAST(  100.0 * CustomerDeclines / NULLIF(TotalAttempts, 0)  AS DECIMAL(10,2) ) AS CustomerDeclineRate,
    AuthenticationDeclines,
    CAST(  100.0 * AuthenticationDeclines / NULLIF(TotalAttempts, 0)  AS DECIMAL(10,2)  ) AS AuthenticationDeclineRate,
    RiskDeclines,
    CAST(   100.0 * RiskDeclines  / NULLIF(TotalAttempts, 0)  AS DECIMAL(10,2) ) AS RiskDeclineRate,
    OtherUnknownDeclines,
    CAST( 100.0 * OtherUnknownDeclines / NULLIF(TotalAttempts, 0)  AS DECIMAL(10,2)  ) AS OtherUnknownDeclineRate

FROM CategoryAnalysis
ORDER BY
    CASE  WHEN IncidentPeriod = 'Before Incident' THEN 1  ELSE 2  END;
       
       
   