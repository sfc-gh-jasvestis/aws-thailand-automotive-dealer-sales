-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-booking alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_BOOKINGS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic booking-issue knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ISSUE_DOCS AS
WITH types AS (
  SELECT DISTINCT r.ISSUE_TYPE, a.CATEGORY
  FROM RAW.DEALER_DAILY r JOIN RAW.DEALERS a ON a.ID = r.ENTITY_ID
  WHERE r.CANCELLED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ISSUE_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ISSUE_TYPE,
  CATEGORY || ' - ' || ISSUE_TYPE || ' booking issue handling' AS TITLE,
  'Synthetic demo SOP. Vehicle segment: ' || CATEGORY || '. Booking issue type: ' || ISSUE_TYPE || '. '
  || 'Step 1: log a booking case in the dealer management system, notify the sales manager, and hold the vehicle allocation for that booking until a reviewer triages the case. '
  || 'Step 2: ' || CASE
       WHEN ISSUE_TYPE = 'Finance application declined' THEN 'check the application with the finance partner for missing income documents, offer the customer a second finance partner or a larger down payment, and confirm the decision within two working days.'
       WHEN ISSUE_TYPE = 'Trade-in valuation dispute' THEN 'repeat the trade-in inspection with a second appraiser, share the written valuation with the customer, and escalate to the used-vehicle manager when the gap stays above 5%.'
       WHEN ISSUE_TYPE = 'Vehicle allocation delay' THEN 'check incoming allocations and stock at nearby dealers in the same network, offer a dealer-to-dealer transfer or an alternative colour, and give the customer a revised delivery date in writing.'
       WHEN ISSUE_TYPE = 'Colour or trim unavailable' THEN 'show the customer in-stock colour and trim options, quote the wait time for the ordered variant, and update the booking only after the customer confirms.'
       WHEN ISSUE_TYPE = 'Pre-delivery inspection defect' THEN 'stop the handover, log the defect with the workshop, rebook the handover after the fix is signed off, and offer a courtesy vehicle if the date slips.'
       WHEN ISSUE_TYPE = 'Home charger installation delay' THEN 'confirm the site survey date with the charger installer, share the installation schedule with the customer, and agree whether the handover goes ahead before the charger is fitted.'
       WHEN ISSUE_TYPE = 'Fleet contract change' THEN 'confirm the revised quantity and specification with the fleet buyer in writing, reissue the quotation, and release any vehicles no longer needed back to network stock.'
       ELSE 'review the issue against the dealer booking history and escalate to the regional sales manager if the cause is unclear.'
     END
  || ' Step 3: keep the case open and schedule a dealer sales review when, after triage, the dealer finance decline rate is above 20% or the average lead response time is above 6 hours. '
  || 'Step 4: close the case with the outcome; for a cancelled or late booking, send the customer an update and add the case to the weekly dealer sales report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ISSUE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ISSUE_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ISSUE_TYPE, CONTENT FROM SEARCH.ISSUE_DOCS);

-- ---------- Finance decline rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.FINANCE_DECLINE_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, FINANCE_DECLINE_PCT::FLOAT AS FINANCE_DECLINE
FROM RAW.DEALER_DAILY;
CREATE OR REPLACE VIEW ML.FINANCE_DECLINE_TRAIN AS
SELECT * FROM ML.FINANCE_DECLINE_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.FINANCE_DECLINE_SERIES);
CREATE OR REPLACE VIEW ML.FINANCE_DECLINE_DETECT AS
SELECT * FROM ML.FINANCE_DECLINE_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.FINANCE_DECLINE_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.FINANCE_DECLINE_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.FINANCE_DECLINE_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'FINANCE_DECLINE',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.FINANCE_DECLINE_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS FINANCE_DECLINE, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.FINANCE_DECLINE_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.FINANCE_DECLINE_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'FINANCE_DECLINE'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.DEALER_SALES_ANALYTICS
  TABLES (
    dealers AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'showrooms', 'dealerships')
      COMMENT = 'One row per dealer (city and vehicle segment), 90-day totals',
    risk AS ML.CANCEL_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day booking-cancellation probability per dealer',
    issues AS CURATED.ISSUE_SUMMARY PRIMARY KEY (ISSUE_TYPE)
      COMMENT = 'Booking issues, cancelled bookings and late deliveries by issue type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Dealer network totals per day'
  )
  RELATIONSHIPS (risk_dealer AS risk (ENTITY_ID) REFERENCES dealers)
  FACTS (
    dealers.issues_f AS ISSUE_COUNT,
    dealers.cancelled_f AS CANCELLED_COUNT,
    dealers.late_f AS LATE_DELIVERY_COUNT,
    dealers.bookings_f AS BOOKING_COUNT,
    dealers.value_f AS BOOKING_VALUE_THB,
    dealers.audit_due_f AS STOCK_AUDIT_DUE,
    dealers.audit_done_f AS STOCK_AUDIT_DONE,
    risk.cancel_prob_f AS CANCEL_PROB_7D,
    issues.type_issues_f AS ISSUE_COUNT,
    issues.type_cancelled_f AS CANCELLED_COUNT,
    issues.type_late_f AS LATE_DELIVERY_COUNT,
    issues.type_value_f AS EXPOSED_VALUE_THB,
    daily.day_issues_f AS ISSUE_COUNT,
    daily.day_cancelled_f AS CANCELLED_COUNT,
    daily.day_value_f AS BOOKING_VALUE_THB
  )
  DIMENSIONS (
    dealers.dealer_id AS ENTITY_ID WITH SYNONYMS = ('dealer', 'showroom', 'entity', 'dealership'),
    dealers.dealer_name AS ENTITY_NAME,
    dealers.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Thai city of the dealer showroom',
    dealers.category AS CATEGORY WITH SYNONYMS = ('vehicle segment', 'segment', 'category'),
    dealers.risk_tier AS RISK_TIER COMMENT = 'Dealer operating risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    issues.issue_type AS ISSUE_TYPE WITH SYNONYMS = ('issue', 'booking issue type', 'issue reason'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    dealers.dealer_count AS COUNT(dealers.dealer_id) WITH SYNONYMS = ('number of dealers', 'number of entities', 'how many dealers'),
    dealers.clean_booking_rate_pct AS 100 * (SUM(dealers.bookings_f) - SUM(dealers.issues_f)) / NULLIF(SUM(dealers.bookings_f), 0)
      WITH SYNONYMS = ('clean booking rate', 'issue-free booking rate')
      COMMENT = 'Bookings without an issue / bookings taken',
    dealers.issue_cancellation_pct AS 100 * SUM(dealers.cancelled_f) / NULLIF(SUM(dealers.issues_f), 0)
      COMMENT = 'Cancelled bookings / booking issues raised',
    dealers.issues_raised AS SUM(dealers.issues_f) WITH SYNONYMS = ('booking issues', 'deal problems'),
    dealers.cancelled_bookings_total AS SUM(dealers.cancelled_f) WITH SYNONYMS = ('cancellations', 'cancelled', 'lost bookings'),
    dealers.late_deliveries AS SUM(dealers.late_f) WITH SYNONYMS = ('late handovers', 'missed delivery dates'),
    dealers.bookings_taken AS SUM(dealers.bookings_f) WITH SYNONYMS = ('bookings', 'vehicle bookings', 'sales volume'),
    dealers.total_booking_value_thb AS SUM(dealers.value_f) WITH SYNONYMS = ('booking value', 'sales value', 'sales in THB'),
    dealers.stock_audit_compliance_pct AS 100 * SUM(dealers.audit_done_f) / NULLIF(SUM(dealers.audit_due_f), 0)
      COMMENT = 'Stock audits completed / stock audits due',
    risk.avg_cancel_prob AS AVG(risk.cancel_prob_f),
    issues.type_issues AS SUM(issues.type_issues_f),
    issues.type_cancelled AS SUM(issues.type_cancelled_f),
    issues.type_late AS SUM(issues.type_late_f),
    issues.type_cancel_share_pct AS 100 * SUM(issues.type_cancelled_f) / NULLIF(SUM(issues.type_issues_f), 0),
    daily.daily_issues AS SUM(daily.day_issues_f),
    daily.daily_cancelled AS SUM(daily.day_cancelled_f),
    daily.daily_booking_value_thb AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Thailand vehicle dealer sales analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.DEALER_SALES_AGENT
  COMMENT = 'Dealer sales assistant over a synthetic Thai vehicle dealer network'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give dealer IDs and numbers with units (THB, %)."
  orchestration: "Use dealer_sales_analyst for bookings, booking value in THB, booking issues, cancelled bookings, late deliveries, clean booking rate, stock audit compliance, dealers, cities, vehicle segments, issue types and cancellation risk. Use sop_search for booking-issue handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: dealer_sales_analyst
      description: "Bookings taken, booking value in THB, booking issues, cancelled bookings, late deliveries, clean booking rate, stock audit compliance, issue types and booking-cancellation risk scores by dealer, city and vehicle segment"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic booking-issue handling SOPs by vehicle segment and issue type"
tool_resources:
  dealer_sales_analyst:
    semantic_view: __DEMO_DB__.APP.DEALER_SALES_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ISSUE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-booking alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), DEALER_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_THB FLOAT, RESPONSE_MINUTES FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION TH_AUTOMOTIVE_DEALER_SALES_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (DEALER_ID, EVENT_TS, AMOUNT_THB, RESPONSE_MINUTES, SOP_HINT)
    SELECT p.DEALER_ID, p.EVENT_TS, p.AMOUNT_THB, p.RESPONSE_MINUTES,
           'Check ' || r.CATEGORY || ' booking-issue SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_BOOKINGS p
    JOIN RAW.DEALERS r ON r.ID = p.DEALER_ID
    LEFT JOIN ML.CANCEL_RISK_SCORES s ON s.ENTITY_ID = p.DEALER_ID
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.DEALER_ID = p.DEALER_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('TH_AUTOMOTIVE_DEALER_SALES_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Booking issue alert',
      'New live booking issues logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_BOOKING_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_BOOKINGS p
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.DEALER_ID = p.DEALER_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.ISSUE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.CANCEL_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.CANCEL_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.CANCEL_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'DEALER_AGE_YEARS', DEALER_AGE_YEARS,
             'FINANCE_DECLINE_PCT', FINANCE_DECLINE_PCT, 'AVG_LEAD_RESPONSE_HRS', AVG_LEAD_RESPONSE_HRS,
             'FINANCE_DECLINE_7D', FINANCE_DECLINE_7D, 'CANCELLED_30D', CANCELLED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:CANCEL::FLOAT, 4) AS CANCEL_PROB_7D,
         CASE WHEN PRED:probability:CANCEL::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:CANCEL::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
