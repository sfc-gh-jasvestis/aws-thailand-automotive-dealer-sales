-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Dealer Network & Sales Intelligence
-- ============================================================================
USE DATABASE DEALER_SALES_INTEL;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.DEALER_INTELLIGENCE_AGENT
  COMMENT = 'Dealer Network & Sales Intelligence AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'DEALER_SALES_INTEL.APP.DEALER_SALES_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'DEALER_SALES_INTEL.SEARCH.CAMPAIGN_PLAYBOOK_SEARCH', TOOL_DESCRIPTION => 'Search documents for Automotive Manufacturing information')
  )
  SYSTEM_PROMPT = 'You are the Dealer Sales Intelligence Agent for 450 automotive dealerships across Thailand.';
