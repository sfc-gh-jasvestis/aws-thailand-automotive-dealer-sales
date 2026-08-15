-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.CAMPAIGN_PLAYBOOK_SEARCH
  ON CAMPAIGN_BRIEF
  ATTRIBUTES CAMPAIGN_TYPE, REGION, TARGET_SEGMENT
  WAREHOUSE = DEALER_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.MARKETING_CAMPAIGNS
);
