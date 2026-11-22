/*
-- Q05: Post-Incident Declined Transactions Profile
-- Question: where are the declined attempts concentrated after April 20?
-- Period: Apr 20 to Jul 6, 2025. Declined attempts only. Retries are included.
-- Each dimension is analyzed on its own; CROSS APPLY puts all dimensions
-- in one list. Share = declines / all declines in that dimension.
-- LEFT JOIN keeps attempts with missing IDs (shown as Unknown ID).
-- Concentration does not prove the cause.
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