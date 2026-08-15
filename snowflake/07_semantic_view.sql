-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.DEALER_SALES_ANALYTICS
  COMMENT = 'Dealer performance, sales forecasting, and NBA analytics'
AS
  TABLES (
    CURATED.DEALER_PERFORMANCE AS dealer_performance,CURATED.REGIONAL_SALES_TRENDS AS regional_sales_trends,CURATED.CUSTOMER_SEGMENTS AS customer_segments,CURATED.INVENTORY_DEMAND_MATCH AS inventory_demand_match
  );
