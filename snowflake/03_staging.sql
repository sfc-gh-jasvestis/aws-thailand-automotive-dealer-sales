-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.DEALER_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.DEALER_DAILY observation
    LEFT JOIN RAW.DEALERS dealer ON dealer.ID = observation.ENTITY_ID
    WHERE dealer.ID IS NULL OR observation.BOOKING_COUNT < 0
       OR observation.BOOKING_VALUE_THB < 0
       OR observation.CANCELLED_COUNT < 0 OR observation.CANCELLED_COUNT > observation.ISSUE_COUNT
       OR observation.ISSUE_COUNT > observation.BOOKING_COUNT
       OR observation.LATE_DELIVERY > observation.CANCELLED_COUNT
       OR observation.STOCK_AUDIT_DONE > observation.STOCK_AUDIT_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
