-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA CURATED;

-- DEALER_PERFORMANCE: Real-time dealer KPIs (sales, conversion, CSI, inventory turn)
-- Source: DEALERS, SALES_TRANSACTIONS, LEADS
CREATE OR REPLACE DYNAMIC TABLE CURATED.DEALER_PERFORMANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DEALER_WH
AS
SELECT * FROM RAW.DEALERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- REGIONAL_SALES_TRENDS: Regional sales trends for forecasting
-- Source: SALES_TRANSACTIONS, DEALERS
CREATE OR REPLACE DYNAMIC TABLE CURATED.REGIONAL_SALES_TRENDS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DEALER_WH
AS
SELECT * FROM RAW.SALES_TRANSACTIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- CUSTOMER_SEGMENTS: AI-derived customer segments for targeting
-- Source: CUSTOMER_PROFILES, SALES_TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.CUSTOMER_SEGMENTS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DEALER_WH
AS
SELECT * FROM RAW.CUSTOMER_PROFILES;
-- TODO: Replace with actual join/aggregation logic per demo

-- INVENTORY_DEMAND_MATCH: Inventory-to-demand matching by region and model
-- Source: INVENTORY, LEADS, SALES_TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.INVENTORY_DEMAND_MATCH
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DEALER_WH
AS
SELECT * FROM RAW.INVENTORY;
-- TODO: Replace with actual join/aggregation logic per demo

