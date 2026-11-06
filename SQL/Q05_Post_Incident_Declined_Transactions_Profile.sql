/*
Project: Payments Analytics World
Query ID: Q05
Query Name: Post-Incident Declined Transactions Profile
Category: Failure Isolation
Tool: SQL Server 2022 (T-SQL)

BUSINESS QUESTION
-----------------
What are the most common characteristics shared by
declined payment attempts after the suspected incident?

BUSINESS OBJECTIVE
------------------
Identify concentrations across payment dimensions
using actual business names.

PERIOD
------
2025-04-20 through 2025-07-06.

METRICS
-------
1. Declined Attempts
2. Share of Total Declines (%)
3. Unknown / Unmapped Attempts

GRAIN
-----
One row per dimension value.

DATA SOURCE
-----------
dbo.FactTransactions
dbo.DimAcquirer
dbo.DimCountry
dbo.DimRoute
dbo.DimPaymentMethod
dbo.DimIssuer
dbo.DimMerchant
dbo.DimDeclineReason

NOTES
-----
- Retries are included.
- Each dimension is analyzed independently.
- LEFT JOIN preserves unmatched transactions.
- Concentration does not establish causation.
*/

WITH PostIncidentDeclines AS
                            (
                               SELECT
                               t.TransactionID,
                                COALESCE(
                       dr.DeclineReasonDescription,
                        CASE WHEN t.DeclineReasonID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID' END ) AS DeclineReason,
                                COALESCE(
                                 c.CountryName,
                                 CASE WHEN t.TransactionCountryID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID'  END) AS CountryName,
                                COALESCE(
                                  r.RouteName,
                                  CASE WHEN t.RouteID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID'  END ) AS RouteName,
                                COALESCE(
                                  pm.PaymentMethodName,
                                  CASE WHEN t.PaymentMethodID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID' END) AS PaymentMethodName,
                                 COALESCE(
                                     a.AcquirerName,
                                   CASE WHEN t.AcquirerID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID' END ) AS AcquirerName,
                                 COALESCE(
                                      i.IssuerName,
                                   CASE WHEN t.IssuerID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID' END ) AS IssuerName,
                                 COALESCE(
                                  m.MerchantName,
                                   CASE WHEN t.MerchantID IS NULL THEN 'Unknown ID' ELSE 'Unmapped ID' END ) AS MerchantName

        FROM dbo.FactTransactions AS t LEFT JOIN dbo.DimDeclineReason AS dr ON t.DeclineReasonID = dr.DeclineReasonID
         LEFT JOIN dbo.DimCountry AS c ON t.TransactionCountryID = c.CountryID
         LEFT JOIN dbo.DimRoute AS r ON t.RouteID = r.RouteID
         LEFT JOIN dbo.DimPaymentMethod AS pm ON t.PaymentMethodID = pm.PaymentMethodID
         LEFT JOIN dbo.DimAcquirer AS a ON t.AcquirerID = a.AcquirerID
         LEFT JOIN dbo.DimIssuer AS i  ON t.IssuerID = i.IssuerID
         LEFT JOIN dbo.DimMerchant AS m   ON t.MerchantID = m.MerchantID

         WHERE
        t.TransactionStatus = 'Declined' AND t.TransactionDateTime >= '20250420'AND t.TransactionDateTime < '20250707'
                           ),

DimensionValues AS
                  (
                    SELECT
                      v.DimensionName,
                      v.DimensionValue

                    FROM PostIncidentDeclines AS d

    CROSS APPLY
    (
        VALUES
            ('Decline Reason', d.DeclineReason),
            ('Country', d.CountryName),
            ('Route', d.RouteName),
            ('Payment Method', d.PaymentMethodName),
            ('Acquirer', d.AcquirerName),
            ('Issuer', d.IssuerName),
            ('Merchant', d.MerchantName)

    ) AS v(DimensionName, DimensionValue)
)

SELECT
    DimensionName,
    DimensionValue,
    COUNT_BIG(*) AS DeclinedAttempts,
    CAST( 100.0 * COUNT_BIG(*) / SUM(COUNT_BIG(*)) OVER (PARTITION BY DimensionName)AS DECIMAL(6,2) ) AS ShareOfDeclinesPct

FROM DimensionValues
GROUP BY
    DimensionName,
    DimensionValue
ORDER BY
   
    DeclinedAttempts DESC;