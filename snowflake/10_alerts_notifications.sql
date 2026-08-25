-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_thailand_automotive_dealer_sales_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: DEALER_UNDERPERFORM_ALERT
CREATE OR REPLACE ALERT APP.DEALER_UNDERPERFORM_ALERT
  WAREHOUSE = DEALER_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Dealer significantly underperforming target'
IF (EXISTS (
  SELECT 1 FROM CURATED.DEALER_PERFORMANCE
  WHERE 1=1 -- Condition: SALES_VS_TARGET < 70% for any dealer for 2 consecutive months
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_automotive_dealer_sales_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Dealer Network & Sales Intelligence: Dealer significantly underperforming target',
    'Dealer significantly underperforming target'
  );

ALTER ALERT APP.DEALER_UNDERPERFORM_ALERT RESUME;

-- Alert: INVENTORY_MISMATCH_ALERT
CREATE OR REPLACE ALERT APP.INVENTORY_MISMATCH_ALERT
  WAREHOUSE = DEALER_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Inventory aging — demand mismatch detected'
IF (EXISTS (
  SELECT 1 FROM CURATED.DEALER_PERFORMANCE
  WHERE 1=1 -- Condition: DAYS_SUPPLY > 90 for any model at any dealer
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_automotive_dealer_sales_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Dealer Network & Sales Intelligence: Inventory aging — demand mismatch detected',
    'Inventory aging — demand mismatch detected'
  );

ALTER ALERT APP.INVENTORY_MISMATCH_ALERT RESUME;

