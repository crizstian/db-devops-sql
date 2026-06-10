-- =============================================================================
-- VALIDATE CHANGELOGS (JSON OUTPUT): Para integración con CI/CD
-- =============================================================================
-- Uso: psql -h <host> -U <user> -d <database> -t -A -f scripts/validate-changelogs-json.sql
-- Retorna JSON con resultado de validaciones
-- =============================================================================

WITH validations AS (
    SELECT '001-00' AS changelog, 'schema_app' AS check_name,
        EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app') AS passed

    UNION ALL
    SELECT '001-00', 'table_customer',
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'customer')

    UNION ALL
    SELECT '002-00', 'column_email',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'app' AND table_name = 'customer' AND column_name = 'email')

    UNION ALL
    SELECT '003-00', 'table_country',
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'country')

    UNION ALL
    SELECT '003-00', 'data_countries',
        (SELECT COUNT(*) FROM app.country WHERE code IN ('MX', 'US', 'CA')) = 3

    UNION ALL
    SELECT '004-00', 'dropped_email',
        NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'app' AND table_name = 'customer' AND column_name = 'email')

    UNION ALL
    SELECT '004-01', 'column_country_code',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'app' AND table_name = 'customer' AND column_name = 'country_code')

    UNION ALL
    SELECT '005-00', 'index_email',
        EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'app' AND tablename = 'customer' AND indexname = 'idx_customer_email')

    UNION ALL
    SELECT '006-00', 'renamed_full_name',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'app' AND table_name = 'customer' AND column_name = 'full_name')

    UNION ALL
    SELECT '007-00', 'view_customer_country',
        EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'app' AND table_name = 'vw_customer_country')

    UNION ALL
    SELECT '008-00', 'backup_table_exists',
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'app' AND table_name = 'customer_email_backup')

    UNION ALL
    SELECT '009-00', 'dangerous_update_blocked',
        (SELECT COUNT(DISTINCT email) FROM app.customer) > 1 OR (SELECT COUNT(*) FROM app.customer) = 0
),
summary AS (
    SELECT
        COUNT(*) FILTER (WHERE passed) AS total_passed,
        COUNT(*) FILTER (WHERE NOT passed) AS total_failed,
        COUNT(*) AS total_checks
    FROM validations
)
SELECT json_build_object(
    'timestamp', NOW(),
    'summary', (SELECT json_build_object(
        'total_checks', total_checks,
        'passed', total_passed,
        'failed', total_failed,
        'success', total_failed = 0
    ) FROM summary),
    'validations', (
        SELECT json_agg(
            json_build_object(
                'changelog', changelog,
                'check', check_name,
                'passed', passed,
                'status', CASE WHEN passed THEN 'PASS' ELSE 'FAIL' END
            ) ORDER BY changelog, check_name
        )
        FROM validations
    )
);
