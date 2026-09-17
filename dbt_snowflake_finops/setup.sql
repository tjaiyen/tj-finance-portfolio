-- One-time account setup: run this once, right after creating the Snowflake trial account,
-- before the first `dbt build`. Requires ACCOUNTADMIN (or an equivalent role) to run itself --
-- everything it creates is scoped to run as something narrower afterward.
--
-- NOT YET RUN AGAINST A LIVE ACCOUNT -- written against verified Snowflake syntax
-- (docs.snowflake.com/en/sql-reference/sql/create-resource-monitor and Snowflake's own dbt-on-
-- Snowflake access-control guidance), but this is the project's first real account, so treat this
-- file as "ready," not "proven," until it's actually been run once.

-- ============================================================================
-- 1. Resource monitor -- a hard credit-usage guardrail, set before anything else runs.
--    Sized for a solo demo project on the $400/30-day trial credit, not production use.
-- ============================================================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR finops_trial_monitor
  WITH
    CREDIT_QUOTA = 25
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND
    ON 110 PERCENT DO SUSPEND_IMMEDIATE;

-- Attach it to the warehouse this project actually uses (FINOPS_XS, per profiles.example.yml).
-- Run this AFTER the warehouse exists (dbt creates it on first connect if it doesn't yet, or
-- create it manually first: CREATE WAREHOUSE FINOPS_XS WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60
-- AUTO_RESUME = TRUE;).
ALTER WAREHOUSE FINOPS_XS SET RESOURCE_MONITOR = finops_trial_monitor;

-- ============================================================================
-- 2. Scoped role for CI/dbt -- replaces ACCOUNTADMIN as the profile's default role.
--    Least-privilege for a solo project: not the full enterprise USERADMIN/SECURITYADMIN
--    hierarchy (that would be over-engineering a one-person demo) -- one role, narrowly granted.
-- ============================================================================
CREATE ROLE IF NOT EXISTS finops_ci_role;

-- Database + warehouse the role needs to operate the pipeline end to end.
CREATE DATABASE IF NOT EXISTS FINOPS_DEV;

GRANT USAGE ON WAREHOUSE FINOPS_XS TO ROLE finops_ci_role;
GRANT OPERATE ON WAREHOUSE FINOPS_XS TO ROLE finops_ci_role;

GRANT USAGE ON DATABASE FINOPS_DEV TO ROLE finops_ci_role;
GRANT CREATE SCHEMA ON DATABASE FINOPS_DEV TO ROLE finops_ci_role;
GRANT USAGE ON SCHEMA FINOPS_DEV.PUBLIC TO ROLE finops_ci_role;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA FINOPS_DEV.PUBLIC TO ROLE finops_ci_role;

-- Future grants: dbt drops and recreates tables/views on every run, so the role needs rights on
-- objects that don't exist yet at grant time, not just the ones that exist right now.
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA FINOPS_DEV.PUBLIC TO ROLE finops_ci_role;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA FINOPS_DEV.PUBLIC TO ROLE finops_ci_role;

-- Grant the role to whichever user profiles.yml actually authenticates as (replace <SNOWFLAKE_USER>).
GRANT ROLE finops_ci_role TO USER <SNOWFLAKE_USER>;

-- After this runs, profiles.yml's SNOWFLAKE_ROLE should be "finops_ci_role", not "ACCOUNTADMIN".
