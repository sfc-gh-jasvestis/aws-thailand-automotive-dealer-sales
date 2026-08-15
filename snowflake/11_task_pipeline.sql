-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_GENERATE_NBA
  WAREHOUSE = DEALER_WH
  SCHEDULE = 'USING CRON 0 6 * * 1 UTC'
  COMMENT = 'Generate weekly NBA recommendations via Cortex Complete'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SEND_OUTREACH
  WAREHOUSE = DEALER_WH
  AFTER APP.TASK_GENERATE_NBA
  COMMENT = 'Send personalized outreach via Notification Integration'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_FORECASTS
  WAREHOUSE = DEALER_WH
  SCHEDULE = 'USING CRON 0 2 * * * UTC'
  COMMENT = 'Refresh regional sales forecasts'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_REFRESH_FORECASTS RESUME;
ALTER TASK APP.TASK_SEND_OUTREACH RESUME;
ALTER TASK APP.TASK_GENERATE_NBA RESUME;
