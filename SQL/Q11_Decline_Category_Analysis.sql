/*
-- Q11: Pre-Post Incident Decline Category Analysis (Acquirer B Overflow Route)
-- Question: was the drop linked to Technical declines or to other categories?
-- Before: Jan 6 to Apr 19. After: Apr 20 to Jul 6, 2025. Retries are included.
-- Only Acquirer B Overflow Route. Categories come from DimDeclineReason.
-- Rate = category declines / all attempts in the period.
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
       
       
   