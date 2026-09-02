-- Generated from generator/demo_specs/aws-thailand-automotive-dealer-sales.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-thailand-automotive-dealer-sales
-- This is the schema that is actually deployed for THAILAND_AUTOMOTIVE_DEALER_SALES.

-- THAILAND_AUTOMOTIVE_DEALER_SALES  (Dealer Network & Sales Intelligence)
-- generated from generator/demo_specs/aws-thailand-automotive-dealer-sales.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS THAILAND_AUTOMOTIVE_DEALER_SALES;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_DEALER_SALES.RAW;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_DEALER_SALES.CURATED;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_DEALER_SALES.APP;
USE DATABASE THAILAND_AUTOMOTIVE_DEALER_SALES;

-- 5 real regions; entity names carry their region so the two always agree
