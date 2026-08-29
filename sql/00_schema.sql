DROP SCHEMA IF EXISTS pastafari_sql_tamil CASCADE;

CREATE SCHEMA pastafari_sql_tamil;

CREATE TYPE pastafari_sql_tamil.calendar_result AS (
    year_number numeric,
    cutlet_index integer,
    day_in_cutlet numeric,
    month_index integer,
    day_in_month numeric
);

CREATE TYPE pastafari_sql_tamil.monster_context AS (
    calculation_day numeric,
    target_day numeric,
    phase text,
    sub_phase integer,
    mode text,
    status text,
    retry_budget integer,
    recovery_depth integer,
    current_handler text,
    previous_handler text,
    branch_trace text[],
    metrics jsonb,
    logs jsonb,
    diagnostics jsonb,
    warnings jsonb,
    last_error text,
    validation_failures text[]
);

CREATE TABLE pastafari_sql_tamil.monster_metrics (
    metric_key text PRIMARY KEY,
    metric_value numeric NOT NULL DEFAULT 0
);

CREATE TABLE pastafari_sql_tamil.monster_logs (
    log_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_code text NOT NULL,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb
);
