CREATE OR REPLACE FUNCTION pastafari_sql_tamil.new_monster_context(p_calculation_day numeric, p_target_day numeric)
RETURNS pastafari_sql_tamil.monster_context
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT ROW(
        p_calculation_day,
        p_target_day,
        'BOOTSTRAP',
        0,
        'AUTHORITATIVE_SPAGHETTI',
        'NEW',
        0,
        0,
        'BaseDispatcher',
        NULL,
        ARRAY['BOOTSTRAP_ENTER']::text[],
        '{}'::jsonb,
        '[]'::jsonb,
        '[]'::jsonb,
        '[]'::jsonb,
        NULL,
        ARRAY[]::text[]
    )::pastafari_sql_tamil.monster_context
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.base_validate_context(p_ctx pastafari_sql_tamil.monster_context)
RETURNS boolean
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT (p_ctx).calculation_day IS NOT NULL
       AND (p_ctx).target_day IS NOT NULL
       AND (p_ctx).phase = 'BOOTSTRAP'
       AND (p_ctx).mode = 'AUTHORITATIVE_SPAGHETTI'
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.base_dispatch(p_ctx pastafari_sql_tamil.monster_context)
RETURNS pastafari_sql_tamil.monster_context
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT ROW(
        (p_ctx).calculation_day,
        (p_ctx).target_day,
        'BOOTSTRAP_VALIDATED',
        1,
        (p_ctx).mode,
        CASE WHEN pastafari_sql_tamil.base_validate_context(p_ctx) THEN 'READY' ELSE 'INVALID' END,
        (p_ctx).retry_budget,
        (p_ctx).recovery_depth,
        'BaseValidator',
        (p_ctx).current_handler,
        array_append((p_ctx).branch_trace,'BOOTSTRAP_VALIDATE'),
        (p_ctx).metrics,
        (p_ctx).logs,
        (p_ctx).diagnostics,
        (p_ctx).warnings,
        CASE WHEN pastafari_sql_tamil.base_validate_context(p_ctx) THEN NULL ELSE 'E_BOOTSTRAP_CONTEXT' END,
        CASE WHEN pastafari_sql_tamil.base_validate_context(p_ctx) THEN (p_ctx).validation_failures ELSE array_append((p_ctx).validation_failures,'E_BOOTSTRAP_CONTEXT') END
    )::pastafari_sql_tamil.monster_context
$$;

CREATE OR REPLACE FUNCTION pastafari_sql_tamil.calendar_date_spaghetti(p_calculation_day numeric, p_target_day numeric)
RETURNS SETOF pastafari_sql_tamil.calendar_result
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT NULL::pastafari_sql_tamil.calendar_result
    WHERE false
$$;
