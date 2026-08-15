# Demo Script: Dealer Network & Sales Intelligence
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake unifies dealer sales data, generates AI-powered next-best-action recommendations for 450 dealers, and automates personalized outreach — replacing fragmented CRM with unified intelligence"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Kittisak Charoenphol** | VP Sales & Distribution | React App (SPCS) | National sales targets, dealer performance, inventory allocation, market share |
| **Patchara Wongsawat** | Regional Sales Manager | Amazon QuickSight | Dealer conversion rates, lead quality, inventory turn, customer satisfaction scores |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | DEALERS (450), SALES_TRANSACTIONS (85000), CUSTOMER_PROFILES (120000), INVENTORY (15000), LEADS (35000), NBA_ACTIONS (2000), MARKETING_CAMPAIGNS (200), THAI_AUTO_MARKET (12) |
| **CURATED** | 4 Dynamic Tables | DEALER_PERFORMANCE, REGIONAL_SALES_TRENDS, CUSTOMER_SEGMENTS, INVENTORY_DEMAND_MATCH |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, AI_EXTRACT | Classification + extraction |
| **Search** | Cortex Search | 200 documents indexed |
| **Agent** | DEALER_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Thailand's largest auto brand operates 450 dealerships nationwide, but fragmented CRM data means ฿3.2B in quarterly sales gap goes unaddressed. AI-powered next-best-action recommendations, personalized outreach, and demand-driven inventory allocation can close the gap — all from unified Snowflake analytics.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "National sales at 82% of target — ฿3.2B gap to close this quarter."

**Action**: Point at the ฿3.2B gap-to-target KPI

### [0:45–1:30] NEXT BEST ACTION

**Show**: Next Best Action tab

> "AI generates personalized NBA for each dealer — incentive packages, inventory swaps, training focus."

**Action**: Show NBA recommendation cards

### [1:30–2:15] DEMAND & INVENTORY

**Show**: Demand & Inventory tab

> "ML.FORECAST projects 15% EV demand surge in Chiang Mai next quarter based on registration trends."

**Action**: Show demand forecast by region and model

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Kittisak asks: 'Which dealers should receive Q4 incentive packages?'"

**Action**: Type: 'Dealers needing incentives ranked by gap-to-target'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **Cortex Complete for Next Best Action** — Only demo generating dealer-specific NBA recommendations with AI and auto-delivering via Notification Integration
2. **ML.FORECAST for regional demand by model** — Demand forecasting at region × model granularity driving inventory allocation
3. **NBA → Notification Integration pipeline** — End-to-end: AI generates recommendation → writes outreach → sends via email
4. **Thai dealer network context** — 450 realistic Thai dealer names across 5 regions with local market dynamics
5. **Dealer anomaly detection** — ML.ANOMALY_DETECTION identifies dealers with sudden performance degradation
6. **Inventory-demand matching via Dynamic Tables** — Real-time inventory reallocation recommendations based on forecast demand signals


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM DEALER_SALES_INTEL.RAW.SALES_TRANSACTIONS` → 85000
- [ ] `SELECT COUNT(*) FROM DEALER_SALES_INTEL.RAW.DEALERS` → 450
- [ ] `SELECT COUNT(*) FROM DEALER_SALES_INTEL.CURATED.DEALER_PERFORMANCE WHERE SALES_VS_TARGET < 0.70` → ~47

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM DEALER_SALES_INTEL.ML.REGIONAL_SALES_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM DEALER_SALES_INTEL.ML.DEALER_PERFORMANCE_ANOMALY_RESULTS` → >=30

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM DEALER_SALES_INTEL.AI.NBA_RECOMMENDATIONS` → 2000

