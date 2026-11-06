# Payments Analytics World

## 1. Project Overview

An end-to-end Payment Analytics project using SQL Server to investigate
payment performance and identify factors associated with authorization
declines.

The project analyzes **404,767 payment authorization attempts**,
including retries, covering **January 6 -- July 6, 2025**.

## 2. Business Problem

Payment Approval Rate experienced a significant decline starting around
**April 20, 2025**.

The investigation aims to identify when the deterioration started, which
Acquirers and Routes were most affected, which Issuers experienced the
largest performance decline, and how decline categories changed after
the incident.

The analysis follows a hypothesis-driven approach, progressively
narrowing potential causes and separating observed findings from
unverified root-cause assumptions.

## 3. Dataset Description

The project uses a relational payment dataset covering January 6 -- July
6, 2025.

### Dataset Scope

  Metric                                   Count
  ------------------------------------ ---------
  Transaction attempts                   404,767
  Unique Transaction IDs                 404,767
  Active customers                        79,427
  Active merchants                           150
  Active Acquirers                             6
  Active Issuers in transaction data           3
  Active Routes                               18
  Active Payment Methods                       9
  Active Countries                            12
  Used Decline Reason IDs                      9
  Refund records                           8,539
  Chargeback records                       1,526

**Database:** SQL Server 2022\
**Retry treatment:** Retry attempts are included in the investigation
unless explicitly stated otherwise.

The active entity counts above are based on distinct IDs appearing in
`FactTransactions`. Refund and chargeback counts represent records, not
necessarily unique original transactions.

### Main Tables

  Table                Description
  -------------------- ---------------------------------------------
  `FactTransactions`   Payment authorization attempts and outcomes
  `FactRefunds`        Refund records
  `FactChargebacks`    Chargeback records
  `DimAcquirer`        Acquirer information
  `DimRoute`           Payment routing information
  `DimIssuer`          Issuer information
  `DimMerchant`        Merchant information
  `DimPaymentMethod`   Payment method details
  `DimDeclineReason`   Decline reason classifications
  `DimCountry`         Country information
  `DimCustomer`        Customer information
  `DimDate`            Calendar attributes

The dataset follows a dimensional modeling structure, with payment
activity stored in fact tables and descriptive attributes maintained in
dimension tables.

## 4. Tools & Technologies

  -----------------------------------------------------------------------
  Tool                                Purpose
  ----------------------------------- -----------------------------------
  SQL Server 2022                     Data querying, analysis, and
                                      investigation

  SQL Server Management Studio (SSMS) SQL development and query execution

  Microsoft Excel                     Data review and validation

  Power BI                            Planned data visualization and
                                      dashboard development
  -----------------------------------------------------------------------

## 5. Key Business KPIs

  -----------------------------------------------------------------------
  KPI                     Definition              Formula
  ----------------------- ----------------------- -----------------------
  Approval Rate           Percentage of approved  Approved Attempts /
                          authorization attempts  Total Attempts × 100

  Decline Rate            Percentage of declined  Declined Attempts /
                          authorization attempts  Total Attempts × 100

  Transaction Mix         Share of total attempts Segment Attempts /
                          handled by a segment    Total Attempts × 100

  Share of Total Declines Share of all declined   Segment Declines /
                          attempts represented by Total Declines × 100
                          a segment               

  Refund Rate             Percentage of eligible  Unique Refunded
                          approved original       Original Transactions /
                          transactions that were  Eligible Approved
                          refunded                Original Transactions ×
                                                  100
  -----------------------------------------------------------------------

**Calculation notes:** - Approval Rate and Decline Rate are calculated
at the authorization-attempt level. - Retries are included unless
explicitly stated otherwise. - Transaction Mix measures traffic
distribution, not performance. - Share of Total Declines measures
decline concentration, not the decline rate. - Refund Rate should count
unique refunded original transactions to avoid double-counting multiple
refunds against one original transaction. The reporting period and
eligible transaction cohort must be aligned.

## 6. Investigation Methodology

The investigation followed a **hypothesis-driven approach**, aiming to
progressively narrow down potential causes of the Approval Rate
deterioration rather than perform unnecessary exploratory analysis.

### Investigation Stages

**1. Performance Assessment (Q01--Q04)**

Analyzed monthly, weekly, and daily Approval Rate trends, identified the
deterioration period, and quantified the difference between Pre-Incident
and Post-Incident performance.

**2. Initial Decline Profiling (Q05)**

Analyzed the distribution of declined attempts across Acquirers, Routes,
Issuers, Payment Methods, Merchants, Countries, and Decline Reasons.

**Important:** This was an initial screening step to identify potential
investigation leads, not to confirm where performance had deteriorated.
Decline counts alone cannot establish a performance problem because they
are also affected by transaction volume.

**3. Pre/Post Performance Validation (Q06)**

Compared Acquirer performance before and after the incident using
Approval Rate, transaction volume, Transaction Mix, and Share of Total
Declines.

This step addressed the main limitation of Q05 by adding performance and
traffic context, helping distinguish high decline concentration from
actual performance deterioration.

**4. Progressive Investigation (Q07--Q11)**

Based on the strongest signal identified in Q06, the analysis
progressively examined: - Route performance within Acquirer B. - Issuer
performance within the Overflow Route. - Daily Issuer performance
trends. - Decline category changes before and after the incident.

Each query tested a specific analytical question derived from the
preceding findings.

### Key Analytical Principles

-   Separate transaction volume, Transaction Mix, and performance
    metrics.
-   Validate decline concentration using Pre/Post performance
    comparisons.
-   Investigate the strongest evidence before expanding the analysis.
-   Avoid treating correlation as proof of causation.
-   Clearly distinguish confirmed findings from unverified hypotheses.

## 7. Key Findings & Results

### 7.1 Overall Payment Performance Deterioration

-   Overall Approval Rate decreased from **85.94% to 83.27%**, a decline
    of **2.67 percentage points** after April 20, 2025.
-   The deterioration persisted throughout the post-incident period.

### 7.2 Acquirer B Was the Main Performance Concern

-   Acquirer B Approval Rate dropped from **85.66% to 75.16%**, a
    decline of **10.49 percentage points**.
-   Its share of total declines increased from **24.39% to 35.97%**.
-   Its Transaction Mix remained relatively stable, indicating that the
    deterioration was not simply caused by a major increase in its
    overall portfolio share.

### 7.3 Significant Traffic Shift Toward the Overflow Route

-   Acquirer B Overflow Route traffic increased from **5,423 to 30,872
    attempts**.
-   Its Transaction Mix within Acquirer B increased from **9.99% to
    70.66%**.
-   Its Approval Rate decreased from **83.79% to 70.86%**, a decline of
    **12.93 percentage points**.
-   Acquirer B Primary Route performance remained relatively stable.

### 7.4 Issuer-Level Performance Deterioration

All three identified active Issuers experienced lower Approval Rates
within the Overflow Route:

  -----------------------------------------------------------------------
  Issuer               Pre-Incident      Post-Incident             Change
                      Approval Rate      Approval Rate 
  -------------- ------------------ ------------------ ------------------
  Tier3 Bank 3               73.27%             54.82%          -18.46 pp

  Tier2 Bank 3               82.24%             73.39%           -8.85 pp

  Tier1 Bank 1               87.91%             79.23%           -8.68 pp
  -----------------------------------------------------------------------

Tier3 Bank 3 experienced the largest deterioration.

### 7.5 Decline Category Analysis

Within Acquirer B Overflow Route:

  Decline Category     Pre-Incident Rate   Post-Incident Rate      Change
  ------------------ ------------------- -------------------- -----------
  Customer                        10.42%               22.84%   +12.42 pp
  Technical                        4.22%                3.60%    -0.62 pp
  Authentication                   1.35%                2.12%    +0.77 pp

The deterioration was primarily associated with an increase in
Customer-category declines, rather than an increase in the Technical
Decline Rate.

**Overall finding:** The strongest observed pattern was a major traffic
shift toward Acquirer B Overflow Route, accompanied by a substantial
decline in its Approval Rate and increased Customer-category declines.
The exact operational root cause remains unconfirmed.

## 8. Business Impact

The investigation identified a measurable deterioration in payment
authorization performance, with the impact concentrated in Acquirer B
Overflow Route.

### Operational Impact

-   Overall Approval Rate decreased by **2.67 percentage points** after
    April 20, 2025.
-   Acquirer B experienced a **10.49 percentage-point** decline in
    Approval Rate.
-   Acquirer B Overflow Route experienced a **12.93 percentage-point**
    decline.
-   Average daily declined attempts increased from approximately **307
    to 387** across the overall payment portfolio, representing an
    increase of approximately **26%**.
-   Within Acquirer B Overflow Route, the Customer Decline Rate
    increased by **12.42 percentage points**.

These findings indicate increased authorization failures and reduced
payment acceptance performance.

### Financial Impact Considerations

Lower Approval Rates may result in lost potential payment volume,
reduced merchant revenue opportunities, increased customer payment
friction, potential customer dissatisfaction, and additional operational
pressure.

However, the dataset does not establish the actual financial loss
attributable to the incident. A reliable financial estimate would
require additional information, including transaction values, recovery
through subsequent retries, customer purchase behavior, and merchant
revenue data.

Therefore, no confirmed financial loss is claimed in this analysis.

## 9. Recommendations

Based on the investigation findings, the following actions are
recommended:

1.  **Review Acquirer B Overflow Routing:** Investigate why transaction
    traffic shifted significantly from the Primary Route to the Overflow
    Route, and review routing rules and configuration changes around
    April 20, 2025.
2.  **Analyze Issuer Authorization Responses:** Obtain detailed issuer
    response codes to understand the underlying reasons behind the
    increase in Customer-category declines, particularly for Tier3 Bank
    3.
3.  **Review Route Performance and Capacity:** Evaluate the Overflow
    Route's processing capacity, configuration, and operational
    performance under increased traffic.
4.  **Strengthen Payment Performance Monitoring:** Monitor Approval Rate
    by Acquirer and Route, Transaction Mix, issuer-level decline
    patterns, decline category trends, and sudden changes in routing
    behavior.

## 10. Limitations & Further Investigation

Although the investigation identified strong patterns associated with
the performance deterioration, some limitations remain:

-   **Routing History:** Historical routing configuration and rule
    changes were not available.
-   **Issuer Response Details:** Detailed issuer response codes were
    unavailable, limiting the ability to identify the underlying reasons
    behind generic decline categories such as Do Not Honor.
-   **Technical Telemetry:** Detailed processor logs, latency, timeout,
    and capacity metrics were not available in the transaction dataset.
-   **Causal Attribution:** The observed relationship between Overflow
    Route traffic and declining Approval Rate does not independently
    establish causation.
-   **Financial Impact:** Actual lost revenue could not be confirmed
    without additional merchant and transaction-level business data.

Further investigation using operational logs and routing configuration
history would be required to confirm the exact root cause.

## 11. SQL Query Inventory

The investigation consists of 11 SQL queries, executed in a progressive
sequence:

  -----------------------------------------------------------------------
  Query                   Analysis                Objective
  ----------------------- ----------------------- -----------------------
  Q01                     Monthly Approval Rate   Identify long-term
                          Trend                   performance trends

  Q02                     Weekly Approval Rate    Narrow down the
                          Trend                   deterioration period

  Q03                     Daily Approval Rate     Identify the
                          Trend                   approximate incident
                                                  start date

  Q04                     Pre/Post Incident       Quantify overall
                          Performance             performance
                                                  deterioration

  Q05                     Post-Incident Declined  Identify potential
                          Transactions Profile    areas of concern

  Q06                     Acquirer Pre/Post       Validate decline
                          Incident Comparison     concentration using
                                                  performance and traffic
                                                  metrics

  Q07                     Acquirer B Route        Identify the route most
                          Performance Analysis    associated with
                                                  deterioration

  Q08                     Issuer Performance      Compare Issuer
                          within Acquirer B       performance within the
                          Overflow Route          affected route

  Q09                     Daily Approval Rate     Examine daily
                          Trend -- Tier3 Bank 3   performance changes for
                                                  the most affected
                                                  Issuer

  Q10                     Revised Daily Issuer    Compare daily
                          Comparison              performance across
                                                  active Issuers

  Q11                     Decline Category        Assess changes in
                          Analysis                decline category rates
  -----------------------------------------------------------------------

### Analysis Periods

-   Full dataset period: January 6 -- July 6, 2025.
-   Incident date: April 20, 2025.
-   Pre-Incident period: January 6 -- April 19, 2025.
-   Post-Incident period: April 20 -- July 6, 2025.
-   Retry attempts are included unless explicitly stated otherwise.

### SQL Files

``` text
SQL/
├── Q01_Monthly_Approval_Rate_Trend.sql
├── Q02_Weekly_Approval_Rate_Trend.sql
├── Q03_Daily_Approval_Rate_Trend.sql
├── Q04_Pre_Post_Incident_Performance.sql
├── Q05_Post_Incident_Declined_Transactions_Profile.sql
├── Q06 — Acquirer Pre_Post Incident Comparison.sql
├── Q07 — Acquirer B Route Performance Analysis.sql
├── Q08 — Issuer Performance within Acquirer B Overflow Route.sql
├── Q09 — Daily Approval Rate Trend Tier3 Bank 3.sql
├── Q10 — Revised Daily Issuer Comparison.sql
└── Q11_Decline_Category_Analysis.sql
```

## 12. Project Status

**SQL Investigation:** Completed (Q01--Q11).

**Root Cause:** Not conclusively confirmed; additional operational data
is required.

**Power BI Dashboard:** Planned as the next project deliverable.
