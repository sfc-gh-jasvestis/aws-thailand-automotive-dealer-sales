# Thailand Dealer Network Sales

**Thailand - Automotive Dealer Sales**
Use case: dealer booking integrity, cancellations, finance declines and dealer document controls

> Dealer sales monitoring for 40 fictional showrooms of a fictional Thai vehicle distributor, in Bangkok, Chiang Mai, Khon Kaen, Chon Buri and Hat Yai. The demo covers dynamic tables, a booking-cancellation classifier evaluated on a time-based holdout, a booking-issue forecast, finance decline rate anomaly detection, a Cortex Agent that cites SOPs, a live booking feed with an alert, and an SPCS app.

## Why Snowflake

- **Dynamic tables** turn dealer-day rows into bookings, booking issues, cancelled bookings, late deliveries and stock audit compliance; `run_core.py` reconciles them against RAW on every build
- **Booking-cancellation classification** gives each dealer a next-7-day probability, evaluated on a time-based holdout
- **Booking-issue forecast** projects 14 days of network-wide booking issues with prediction intervals, to plan sales desk cover
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, Search over SOPs) shows the SQL it ran and the SOPs it cited
- **Live bookings**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), feeding an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.DEALERS` (40 rows) |
| Fact table | `RAW.DEALER_DAILY` (3,600 dealer-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `ISSUE_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.CANCEL_RISK_SCORES`, `ML.CANCEL_RISK_HOLDOUT_METRICS`, `ML.ISSUE_FORECAST`, `ML.FINANCE_DECLINE_ANOMALIES` |

Currency: THB. Cities: Bangkok, Chiang Mai, Khon Kaen, Chon Buri, Hat Yai.
Vehicle segments: Pickup truck, Eco car, SUV, Electric vehicle, Commercial van.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Clean Booking Rate | 96.49% |
| Booking Issues Raised | 568 |
| Cancelled Bookings | 139 |
| Issue Cancellation Rate | 24.5% |
| Late Deliveries | 68 |
| Booking Value (THB M) | 14,541 |
| Bookings Taken | 16,180 |
| Stock Audit Compliance | 78.5% |
| Dealers Monitored | 40 |
| Compliance Document Coverage | 56.4% |
| Compliance Documents Pending | 17 |

Values are synthetic. The data is HASH-seeded, so a rebuild reproduces them; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPI cards, daily booking issues against cancelled bookings, issues and cancellations by issue type, and the dealer table
2. Predictive: holdout metrics, risk bands, the 14-day booking-issue forecast and finance decline rate anomalies
3. Controls: stock audit compliance, dealer document coverage and pending documents, stock audit compliance against cancelled bookings, then the action memo
4. Live Bookings: run `CALL APP.SIMULATE_BOOKINGS(20)` (Snowflake only) or `python aws/publish_bookings.py --count 20` (AWS build), then `EXECUTE ALERT APP.LIVE_BOOKING_ALERT`, and show the alert log and email
5. Ask AI: the Cortex Agent answers metric questions through the semantic view, cites SOPs from Cortex Search and shows its SQL
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 96.49% of vehicle bookings go through without an issue. The 568 booking issues are where the sales desks spend their time, and about one in four (24.5%) ends as a cancelled booking.
- Declined finance applications cause the most cancelled bookings (54 of 195 issues). The flood-related delivery disruptions in Hat Yai and Chiang Mai hit every dealer in the city on one day and were all resolved.
- Chiang Mai dealers have the most cancelled bookings (39); Hat Yai has the fewest (17).
- On a time-based holdout the risk model reaches precision 0.50 and recall 0.37 at 0.5, against a 0.19 base rate. Use it to decide which dealer gets a sales review first, not as a verdict on a dealer.
- Flood-related delivery disruptions are left out of model training because the dealer did not cause them.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
