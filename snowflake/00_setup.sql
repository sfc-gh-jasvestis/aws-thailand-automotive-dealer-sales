-- ============================================================================
-- Dealer Network & Sales Intelligence
-- Sales intelligence across 450 Thai dealerships — Personalize drives next-best-action recommendations, Cortex Complete generates personalized outreach, and SES delivers through Notification Integration.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS DEALER_SALES_INTEL;
CREATE WAREHOUSE IF NOT EXISTS DEALER_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE DEALER_SALES_INTEL;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE DEALER_WH;
