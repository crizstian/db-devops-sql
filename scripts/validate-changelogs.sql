-- =============================================================================
-- VALIDATE CHANGELOGS: Verifica que cada changelog se ejecutó correctamente
-- =============================================================================
-- Uso: psql -h <host> -U <user> -d <database> -f scripts/validate-changelogs.sql
-- =============================================================================

\echo '=============================================='
\echo 'VALIDACION DE CHANGELOGS - INICIO'
\echo '=============================================='
\echo ''

-- -----------------------------------------------------------------------------
-- 001-00: CREATE SCHEMA AND TABLES
-- -----------------------------------------------------------------------------
\echo '[001-00] Validando schema y tabla customer...'

SELECT
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app')
        THEN '✅ PASS: Schema app existe'
        ELSE '❌ FAIL: Schema app NO existe'
    END AS "001-00-01 Schema";

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'app' AND table_name = 'customer'
        )
        THEN '✅ PASS: Tabla app.customer existe'
        ELSE '❌ FAIL: Tabla app.customer NO existe'
    END AS "001-00-02 Table";

-- -----------------------------------------------------------------------------
-- 002-00: ADD COLUMN EMAIL
-- -----------------------------------------------------------------------------
\echo ''
\echo '[002-00] Validando columna email en customer...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'email'
        )
        THEN '✅ PASS: Columna email existe'
        ELSE '❌ FAIL: Columna email NO existe'
    END AS "002-00-01 Column";

-- -----------------------------------------------------------------------------
-- 003-00: SEED REFERENCE DATA (country table)
-- -----------------------------------------------------------------------------
\echo ''
\echo '[003-00] Validando tabla country y datos de referencia...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'app' AND table_name = 'country'
        )
        THEN '✅ PASS: Tabla app.country existe'
        ELSE '❌ FAIL: Tabla app.country NO existe'
    END AS "003-00-01 Table";

SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM app.country WHERE code IN ('MX', 'US', 'CA')) = 3
        THEN '✅ PASS: Datos de referencia (MX, US, CA) existen'
        ELSE '❌ FAIL: Faltan datos de referencia'
    END AS "003-00-02 Data";

-- -----------------------------------------------------------------------------
-- 004-00: DROP COLUMN EMAIL (si se ejecutó)
-- -----------------------------------------------------------------------------
\echo ''
\echo '[004-00] Validando DROP de columna email...'

SELECT
    CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'email'
        )
        THEN '✅ PASS: Columna email fue eliminada'
        ELSE '⚠️  SKIP: Columna email aún existe (changelog no ejecutado o rollback)'
    END AS "004-00-01 Drop Column";

-- -----------------------------------------------------------------------------
-- 004-01: ADD COLUMN COUNTRY_CODE
-- -----------------------------------------------------------------------------
\echo ''
\echo '[004-01] Validando columna country_code...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'country_code'
        )
        THEN '✅ PASS: Columna country_code existe'
        ELSE '❌ FAIL: Columna country_code NO existe'
    END AS "004-01-01 Column";

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'country_code'
              AND data_type = 'character'
              AND character_maximum_length = 2
        )
        THEN '✅ PASS: country_code es CHAR(2)'
        ELSE '⚠️  WARN: country_code tipo incorrecto o no existe'
    END AS "004-01-02 Type";

-- -----------------------------------------------------------------------------
-- 005-00: CREATE INDEX ON EMAIL
-- -----------------------------------------------------------------------------
\echo ''
\echo '[005-00] Validando índice en email...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes
            WHERE schemaname = 'app'
              AND tablename = 'customer'
              AND indexname = 'idx_customer_email'
        )
        THEN '✅ PASS: Índice idx_customer_email existe'
        ELSE '⚠️  SKIP: Índice idx_customer_email NO existe'
    END AS "005-00-01 Index";

-- -----------------------------------------------------------------------------
-- 006-00: RENAME COLUMN name -> full_name
-- -----------------------------------------------------------------------------
\echo ''
\echo '[006-00] Validando rename de columna name a full_name...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'full_name'
        )
        AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'name'
        )
        THEN '✅ PASS: Columna renombrada a full_name'
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'app'
              AND table_name = 'customer'
              AND column_name = 'name'
        )
        THEN '⚠️  SKIP: Columna aún se llama name (changelog no ejecutado)'
        ELSE '❌ FAIL: Estado inconsistente de columnas'
    END AS "006-00-01 Rename";

-- -----------------------------------------------------------------------------
-- 007-00: CREATE VIEW customer_country
-- -----------------------------------------------------------------------------
\echo ''
\echo '[007-00] Validando vista vw_customer_country...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.views
            WHERE table_schema = 'app'
              AND table_name = 'vw_customer_country'
        )
        THEN '✅ PASS: Vista vw_customer_country existe'
        ELSE '❌ FAIL: Vista vw_customer_country NO existe'
    END AS "007-00-01 View";

-- Validar que la vista es seleccionable
DO $$
BEGIN
    PERFORM * FROM app.vw_customer_country LIMIT 1;
    RAISE NOTICE '✅ PASS: Vista vw_customer_country es consultable';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ FAIL: Vista vw_customer_country no es consultable: %', SQLERRM;
END $$;

-- -----------------------------------------------------------------------------
-- 008-00: UPDATE EMAIL DOMAIN
-- -----------------------------------------------------------------------------
\echo ''
\echo '[008-00] Validando update de dominio email...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'app'
              AND table_name = 'customer_email_backup'
        )
        THEN '✅ PASS: Tabla de backup customer_email_backup existe'
        ELSE '⚠️  SKIP: No hay backup (changelog no ejecutado o sin datos afectados)'
    END AS "008-00-01 Backup";

SELECT
    CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM app.customer
            WHERE email LIKE '%@oldcorp.com'
        )
        THEN '✅ PASS: No hay emails con @oldcorp.com'
        ELSE '⚠️  WARN: Aún existen emails con @oldcorp.com'
    END AS "008-00-02 Domain";

-- -----------------------------------------------------------------------------
-- 009-00: DANGEROUS UPDATE (sin WHERE) - NO debería ejecutarse
-- -----------------------------------------------------------------------------
\echo ''
\echo '[009-00] Validando que UPDATE peligroso NO se ejecutó...'

SELECT
    CASE
        WHEN (
            SELECT COUNT(DISTINCT email) FROM app.customer
        ) > 1 OR (SELECT COUNT(*) FROM app.customer) = 0
        THEN '✅ PASS: Emails son diversos (UPDATE sin WHERE no ejecutado)'
        WHEN (
            SELECT COUNT(*) FROM app.customer
            WHERE email = 'default@company.com'
        ) = (SELECT COUNT(*) FROM app.customer)
        AND (SELECT COUNT(*) FROM app.customer) > 0
        THEN '❌ FAIL: TODOS los emails son default@company.com (UPDATE peligroso ejecutado!)'
        ELSE '⚠️  WARN: Estado indeterminado'
    END AS "009-00-01 Dangerous";

-- -----------------------------------------------------------------------------
-- LIQUIBASE TRACKING
-- -----------------------------------------------------------------------------
\echo ''
\echo '[LIQUIBASE] Validando tracking de changelogs...'

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = 'databasechangelog'
        )
        THEN '✅ PASS: Tabla databasechangelog existe'
        ELSE '❌ FAIL: Tabla databasechangelog NO existe'
    END AS "Liquibase Tracking";

-- Mostrar changelogs ejecutados
\echo ''
\echo 'Changelogs registrados en Liquibase:'
SELECT
    id,
    author,
    filename,
    dateexecuted,
    exectype
FROM databasechangelog
ORDER BY orderexecuted;

-- -----------------------------------------------------------------------------
-- RESUMEN ESTRUCTURA FINAL
-- -----------------------------------------------------------------------------
\echo ''
\echo '=============================================='
\echo 'ESTRUCTURA ACTUAL DE app.customer'
\echo '=============================================='

SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'app' AND table_name = 'customer'
ORDER BY ordinal_position;

\echo ''
\echo '=============================================='
\echo 'INDICES EN app.customer'
\echo '=============================================='

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'app' AND tablename = 'customer';

\echo ''
\echo '=============================================='
\echo 'VALIDACION COMPLETADA'
\echo '=============================================='
