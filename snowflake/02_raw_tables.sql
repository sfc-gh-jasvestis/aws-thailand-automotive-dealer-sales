-- Synthetic dealer-day observations for a fictional Thai vehicle distributor.
-- A dealer is one fictional showroom in one Thai city selling one vehicle segment.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-dealer cancellation propensity, stock drift between
-- yard stock audits, missed stock audits, segment-weighted booking issue types,
-- issues resolved without cancellation, and two city-wide flood disruptions.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.DEALERS AS
WITH dealers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DEALER_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT DEALER_INDEX,
         MOD(ABS(HASH(DEALER_INDEX, 'thdlr-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(DEALER_INDEX, 'thdlr-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(DEALER_INDEX, 'thdlr-audit')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(DEALER_INDEX, 'thdlr-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(DEALER_INDEX, 'thdlr-tier')), 1000000) / 1e6 AS U_TIER
  FROM dealers
)
SELECT 'DLR-' || LPAD(DEALER_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic dealer ' || LPAD(DEALER_INDEX::VARCHAR, 4, '0') AS NAME,
       -- 5 and 8 are coprime, so 40 dealers cover every city and segment slot once.
       CASE MOD(DEALER_INDEX, 5) WHEN 0 THEN 'Bangkok' WHEN 1 THEN 'Chiang Mai'
            WHEN 2 THEN 'Khon Kaen' WHEN 3 THEN 'Chon Buri' ELSE 'Hat Yai' END AS REGION,
       CASE MOD(DEALER_INDEX, 8) WHEN 0 THEN 'Pickup truck' WHEN 1 THEN 'Pickup truck'
            WHEN 2 THEN 'Pickup truck' WHEN 3 THEN 'Eco car' WHEN 4 THEN 'Eco car'
            WHEN 5 THEN 'SUV' WHEN 6 THEN 'Electric vehicle' ELSE 'Commercial van' END AS CATEGORY,
       DEALER_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.5 + U_AGE * 14.5, 1) AS DEALER_AGE_YEARS,
       -- Base daily probability of a cancelled booking 0.5%-3%; ~15% of dealers are
       -- chronically weak (x3).
       (0.005 + U_RATE * 0.025) * IFF(U_RATE > 0.85, 3, 1) AS BASE_CANCEL_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS STOCK_AUDIT_INTERVAL_DAYS,
       0.5 + U_DISCIPLINE * 0.5 AS STOCK_AUDIT_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.DEALER_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide flood disruptions; every dealer in the city raises a booking
  -- issue that is resolved once roads and transporters run again.
  SELECT * FROM VALUES (27, 'Hat Yai'), (64, 'Chiang Mai') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.DEALER_INDEX, s.CATEGORY, s.REGION, s.DEALER_AGE_YEARS,
         s.BASE_CANCEL_RATE, s.STOCK_AUDIT_INTERVAL_DAYS, s.STOCK_AUDIT_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + s.DEALER_INDEX * 3, s.STOCK_AUDIT_INTERVAL_DAYS) AS DAYS_SINCE_AUDIT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-cancel')), 1000000) / 1e6 AS U_CANCEL,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-resolve')), 1000000) / 1e6 AS U_RESOLVE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thdlr-late')), 1000000) / 1e6 AS U_LATE,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.DEALERS s CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), audit AS (
  SELECT *,
         IFF(DAYS_SINCE_AUDIT = 0, 1, 0) AS STOCK_AUDIT_DUE,
         IFF(DAYS_SINCE_AUDIT = 0 AND U_DONE < STOCK_AUDIT_COMPLETION_PROB, 1, 0) AS STOCK_AUDIT_DONE,
         -- Stock drift (system stock versus yard stock) rises between stock
         -- audits; weak audit discipline carries it over.
         DAYS_SINCE_AUDIT / STOCK_AUDIT_INTERVAL_DAYS + (1 - STOCK_AUDIT_COMPLETION_PROB) AS DRIFT
  FROM base
), cancels AS (
  SELECT *,
         CASE WHEN U_CANCEL < LEAST(0.5, BASE_CANCEL_RATE * (0.4 + 1.6 * DRIFT) * (1 + 2 / (2 + DEALER_AGE_YEARS))) / 4 THEN 2
              WHEN U_CANCEL < LEAST(0.5, BASE_CANCEL_RATE * (0.4 + 1.6 * DRIFT) * (1 + 2 / (2 + DEALER_AGE_YEARS))) THEN 1
              ELSE 0 END AS CANCEL_RISK_COUNT
  FROM audit
), issues AS (
  SELECT *,
         -- About 80% of at-risk bookings raise an issue and end cancelled; the
         -- rest are handed over late without an issue.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.8, CANCEL_RISK_COUNT, 0)) AS CANCELLED_COUNT,
         -- Issues resolved without cancellation: higher for newer segments.
         IFF(CITY_EVENT, 1, IFF(U_RESOLVE < CASE CATEGORY WHEN 'Electric vehicle' THEN 0.18
                                                          WHEN 'Eco car' THEN 0.13
                                                          WHEN 'SUV' THEN 0.15 ELSE 0.09 END, 1, 0)) AS RESOLVED_COUNT
  FROM cancels
), measured AS (
  SELECT *,
         CANCELLED_COUNT + RESOLVED_COUNT AS ISSUE_COUNT,
         CASE CATEGORY WHEN 'Pickup truck' THEN 6 WHEN 'Eco car' THEN 5 WHEN 'SUV' THEN 3
                       WHEN 'Electric vehicle' THEN 2.5 ELSE 1.5 END
           * (0.7 + 0.6 * U_VOLUME) * (1 + 0.5 * CANCEL_RISK_COUNT) AS BOOKING_RAW,
         CASE CATEGORY WHEN 'Pickup truck' THEN 950000 WHEN 'Eco car' THEN 560000
                       WHEN 'SUV' THEN 1350000 WHEN 'Electric vehicle' THEN 1150000 ELSE 1250000 END
           * (0.85 + 0.3 * U_NOISE) AS AVG_PRICE_THB
  FROM issues
), counted AS (
  -- A booking issue always belongs to a booking taken that day.
  SELECT *, GREATEST(ISSUE_COUNT, ROUND(BOOKING_RAW)) AS BOOKING_COUNT FROM measured
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       BOOKING_COUNT,
       ROUND(BOOKING_COUNT * AVG_PRICE_THB, 0) AS BOOKING_VALUE_THB,
       ISSUE_COUNT, CANCELLED_COUNT,
       IFF(CANCELLED_COUNT > 0 AND U_LATE < 0.55, 1, 0) AS LATE_DELIVERY,
       CASE WHEN ISSUE_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Flood-related delivery disruption'
            WHEN CATEGORY = 'Pickup truck' THEN IFF(U_TYPE < 0.5, 'Finance application declined', IFF(U_TYPE < 0.8, 'Trade-in valuation dispute', 'Vehicle allocation delay'))
            WHEN CATEGORY = 'Eco car' THEN IFF(U_TYPE < 0.55, 'Finance application declined', 'Colour or trim unavailable')
            WHEN CATEGORY = 'SUV' THEN IFF(U_TYPE < 0.45, 'Vehicle allocation delay', IFF(U_TYPE < 0.8, 'Trade-in valuation dispute', 'Pre-delivery inspection defect'))
            WHEN CATEGORY = 'Electric vehicle' THEN IFF(U_TYPE < 0.45, 'Vehicle allocation delay', IFF(U_TYPE < 0.8, 'Home charger installation delay', 'Finance application declined'))
            ELSE IFF(U_TYPE < 0.5, 'Fleet contract change', IFF(U_TYPE < 0.75, 'Vehicle allocation delay', 'Pre-delivery inspection defect')) END AS ISSUE_TYPE,
       STOCK_AUDIT_DUE, STOCK_AUDIT_DONE,
       ROUND(4 + 6 * DRIFT + 9 * CANCEL_RISK_COUNT + U_NOISE * 3, 2) AS FINANCE_DECLINE_PCT,
       ROUND(1.5 + 3 * DRIFT + 4 * CANCEL_RISK_COUNT + U_NOISE * 1.5, 1) AS AVG_LEAD_RESPONSE_HRS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM counted;

-- Dealer document coverage (snapshot).
CREATE TABLE RAW.COMPLIANCE_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Pickup truck' THEN 'Demo vehicle registration file'
                     WHEN 'Eco car' THEN 'Finance partner agreement'
                     WHEN 'SUV' THEN 'Test-drive insurance certificate'
                     WHEN 'Electric vehicle' THEN 'Charger safety inspection record'
                     ELSE 'Fleet sales contract file' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'thdlr-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'thdlr-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'thdlr-file')), 5) < 1 + MOD(ABS(HASH(ID, 'thdlr-req')), 4),
           MOD(ABS(HASH(ID, 'thdlr-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.DEALERS;
