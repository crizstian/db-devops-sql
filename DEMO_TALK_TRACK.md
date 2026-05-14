# Database DevOps Demo - Talk Track Ejecutivo

**Duración:** 15 minutos | **Audiencia:** Ejecutiva | **Objetivo:** Demostrar gobernanza y automatización de cambios de BD

---

## Vista General del Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           HARNESS DB DevOps PIPELINE                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│   TRIGGER: Pull Request en Git                                                      │
│   ════════════════════════════════════════════════════════════════════════════════  │
│                                                                                     │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│   │  STAGE 1        │    │  STAGE 2        │    │  STAGE 3        │                │
│   │  Quality Check  │ ──▶│  DB Validate    │ ──▶│  DB Deploy      │                │
│   │                 │    │                 │    │                 │                │
│   │  • Semgrep      │    │  • Liquibase    │    │  • Apply Schema │                │
│   │  • Naming Conv. │    │  • OPA Policy   │    │  • Wait/Approve │                │
│   │                 │    │  • JIRA Ticket  │    │  • Rollback     │                │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘                │
│         │                       │                       │                          │
│         ▼                       ▼                       ▼                          │
│   [PR Abierto]           [PR Merged]             [PR Merged]                       │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Agenda (15 min)

| Min | Sección | Escenario |
|-----|---------|-----------|
| 0-2 | Contexto | Por qué Database DevOps |
| 2-4 | Escenario 1 | Developer crea nueva tabla ✅ |
| 4-6 | Escenario 2 | Negocio solicita nuevo campo ✅ → **OPA BLOQUEA** por tener un autor ❌|
| 6-8 | Escenario 3 | Developer intenta DROP → **OPA BLOQUEA** ❌ |
| 8-10 | Escenario 4 | Insertar datos de prueba ✅ |
| 10-12 | Escenario 5 | UPDATE sin WHERE → **OPA BLOQUEA** ❌ |
| 12-15 | Cierre | ROI y próximos pasos |

---

## Contexto (2 min)

> **Hook:** "El 59% de los incidentes en producción involucran cambios de base de datos."

```
ANTES                                    DESPUÉS (Database DevOps)
═══════════════════════════════════════════════════════════════════════
                                         
  📧 Scripts en email                    📁 Versionados en Git
       ↓                                       ↓
  🙏 "Confía en mí"                      🔍 Validación automática
       ↓                                       ↓
  😰 Ejecución manual                    🤖 Pipeline automatizado
       ↓                                       ↓
  🔥 Rollback de 4-8 hrs                 ⏱️  Rollback en 2 min
```

---

## Escenario 1: Developer Crea Nueva Tabla ✅

### Historia
> "El equipo de desarrollo necesita crear el esquema inicial para la aplicación de clientes."

### Flujo Visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCENARIO 1: CREATE TABLE                                                    │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEVELOPER                  GIT                    HARNESS PIPELINE          │
│  ══════════                 ═══                    ════════════════          │
│                                                                              │
│  📝 Crea changeset    ──▶   🔀 Pull Request   ──▶  ┌─────────────────┐      │
│     001-00-init-             abierto               │ Quality Check   │      │
│     schema.yaml                                    │ ✅ Semgrep      │      │
│                                                    │ ✅ Naming Conv  │      │
│                                                    └────────┬────────┘      │
│                                                             │               │
│                         🔀 PR Merged        ──▶  ┌─────────────────┐        │
│                                                  │ DB Validate     │        │
│                                                  │ ✅ Liquibase    │        │
│                                                  │ ✅ OPA Policy   │        │
│                                                  │ 📋 JIRA Ticket  │        │
│                                                  └────────┬────────┘        │
│                                                           │                 │
│                                                  ┌─────────────────┐        │
│                                                  │ DB Deploy       │        │
│                                                  │ ✅ Apply Schema │        │
│                                                  │ ✅ SUCCESS      │        │
│                                                  └─────────────────┘        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Código Demo

```sql
-- scripts/ddl/001-00-01-create-schema-and-tables.sql
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.customer (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Rollback Incluido

```sql
-- scripts/rollback/001-00/001-00-01-rollback.sql
DROP TABLE IF EXISTS app.customer;
DROP SCHEMA IF EXISTS app;
```

> **Punto clave:** "Cada changeset tiene su rollback. Si algo sale mal, revertimos en minutos, no horas."

---

## Escenario 2: Negocio Solicita Nuevo Campo ✅

### Historia
> "Marketing necesita el email de los clientes para campañas."

### Flujo Visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCENARIO 2: ALTER TABLE ADD COLUMN                                          │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PRODUCT OWNER              DEVELOPER              HARNESS PIPELINE          │
│  ═════════════              ═════════              ════════════════          │
│                                                                              │
│  📋 "Necesitamos     ──▶   📝 Crea changeset  ──▶  ┌─────────────────┐      │
│      email de               002-00-add-column      │ Quality Check   │      │
│      clientes"              customer.yaml          │ ✅ Passed       │      │
│                                                    └────────┬────────┘      │
│                                                             │               │
│                                                    ┌─────────────────┐      │
│                                                    │ DB Validate     │      │
│                                                    │ ✅ OPA: safe    │      │
│                                                    │ ✅ No destructive│     │
│                                                    └────────┬────────┘      │
│                                                             │               │
│                                                    ┌─────────────────┐      │
│                                                    │ DB Deploy       │      │
│                                                    │ ✅ Column added │      │
│                                                    └─────────────────┘      │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Código Demo

```sql
-- scripts/ddl/002-00-01-add-column-customer_email.sql
ALTER TABLE app.customer
ADD COLUMN email TEXT;

COMMENT ON COLUMN app.customer.email IS 'Customer email address';
```

> **Punto clave:** "El mismo rigor que código aplicativo: PR → Review → Merge → Deploy automático."

---

## Escenario 3: DROP Column → OPA BLOQUEA ❌

### Historia
> "Un developer junior intenta eliminar una columna 'que ya no se usa'."

### Flujo Visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCENARIO 3: DROP COLUMN - ❌ BLOQUEADO POR OPA                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEVELOPER                  GIT                    HARNESS PIPELINE          │
│  ══════════                 ═══                    ════════════════          │
│                                                                              │
│  📝 Crea changeset    ──▶   🔀 Pull Request   ──▶  ┌─────────────────┐      │
│     004-00-drop-             abierto               │ Quality Check   │      │
│     column-email.yaml                              │ ✅ Passed       │      │
│                                                    └────────┬────────┘      │
│  ⚠️  DROP COLUMN                                            │               │
│                                                    ┌─────────────────┐      │
│                         🔀 PR Merged        ──▶    │ DB Validate     │      │
│                                                    │                 │      │
│                                                    │  ┌───────────┐  │      │
│                                                    │  │ OPA CHECK │  │      │
│                                                    │  │           │  │      │
│                                                    │  │  ❌ DENY  │  │      │
│                                                    │  │           │  │      │
│                                                    │  │ "DROP not │  │      │
│                                                    │  │  allowed  │  │      │
│                                                    │  │  in prod" │  │      │
│                                                    │  └───────────┘  │      │
│                                                    │                 │      │
│                                                    │ ❌ BLOCKED      │      │
│                                                    └─────────────────┘      │
│                                                                              │
│  🚫 PIPELINE DETENIDO - Cambio destructivo requiere aprobación DBA          │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Código que OPA Detecta

```sql
-- scripts/ddl/004-00-01-drop-column-email.sql
ALTER TABLE app.customer
DROP COLUMN IF EXISTS email;    -- ⚠️ OPA detecta "DROP"
```

### Policy OPA (Enforce_SQL_Compliance)

```rego
# OPA Policy: Bloquear DROP en producción
deny["DROP statements not allowed in production"] {
    input.sql contains "DROP"
    input.environment == "production"
}
```

> **Punto clave:** "OPA actúa como guardián. El código nunca llega a producción sin cumplir las policies."

---

## Escenario 4: Insertar Datos de Referencia ✅

### Historia
> "La aplicación necesita catálogo de países para el módulo de registro."

### Flujo Visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCENARIO 4: INSERT DATA (DML)                                               │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEVELOPER                  HARNESS PIPELINE                                 │
│  ══════════                 ════════════════                                 │
│                                                                              │
│  📝 Crea changeset    ──▶   ┌─────────────────┐                             │
│     003-00-seed-            │ DB Validate     │                             │
│     reference-data          │                 │                             │
│                             │ ✅ OPA: safe    │                             │
│  📊 INSERT con              │ ✅ Idempotent   │                             │
│     ON CONFLICT             │    (ON CONFLICT)│                             │
│                             └────────┬────────┘                             │
│                                      │                                      │
│                             ┌─────────────────┐                             │
│                             │ DB Deploy       │                             │
│                             │ ✅ 3 rows added │                             │
│                             │ ✅ SUCCESS      │                             │
│                             └─────────────────┘                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Código Demo

```sql
-- scripts/dml/003-00-01-insert-country-reference.sql
CREATE TABLE IF NOT EXISTS app.country (
    code CHAR(2) PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO app.country (code, name) VALUES
    ('MX', 'Mexico'),
    ('US', 'United States'),
    ('CA', 'Canada')
ON CONFLICT (code) DO NOTHING;  -- ✅ Idempotente
```

> **Punto clave:** "ON CONFLICT garantiza idempotencia. Puede ejecutarse múltiples veces sin duplicar datos."

---

## Escenario 5: UPDATE sin WHERE → OPA BLOQUEA ❌

### Historia
> "Un developer olvida el WHERE en un UPDATE masivo."

### Flujo Visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCENARIO 5: UPDATE SIN WHERE - ❌ BLOQUEADO POR OPA                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEVELOPER                  GIT                    HARNESS PIPELINE          │
│  ══════════                 ═══                    ════════════════          │
│                                                                              │
│  📝 Crea changeset    ──▶   🔀 Pull Request   ──▶  ┌─────────────────┐      │
│     009-00-update-           abierto               │ Quality Check   │      │
│     all-emails.yaml                                │ ✅ Passed       │      │
│                                                    └────────┬────────┘      │
│  ⚠️  UPDATE sin WHERE                                       │               │
│      (afecta TODAS                                 ┌─────────────────┐      │
│       las filas)                                   │ DB Validate     │      │
│                                                    │                 │      │
│                                                    │  ┌───────────┐  │      │
│                                                    │  │ OPA CHECK │  │      │
│                                                    │  │           │  │      │
│                                                    │  │  ❌ DENY  │  │      │
│                                                    │  │           │  │      │
│                                                    │  │ "UPDATE   │  │      │
│                                                    │  │  without  │  │      │
│                                                    │  │  WHERE"   │  │      │
│                                                    │  └───────────┘  │      │
│                                                    │                 │      │
│                                                    │ ❌ BLOCKED      │      │
│                                                    └─────────────────┘      │
│                                                                              │
│  🚫 PIPELINE DETENIDO - UPDATE sin WHERE es potencialmente destructivo      │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Código que OPA Detecta

```sql
-- scripts/dml/009-00-01-update-all-emails.sql
UPDATE app.customer
SET email = 'default@company.com';  -- ⚠️ Sin WHERE = afecta TODAS las filas
```

### Policy OPA (Enforce_SQL_Compliance)

```rego
# OPA Policy: Bloquear UPDATE sin WHERE
deny["UPDATE without WHERE clause is not allowed"] {
    input.sql contains "UPDATE"
    not contains(input.sql, "WHERE")
}
```

### Contraste: UPDATE Correcto ✅

```sql
-- scripts/dml/008-00-01-update-email-domain.sql (CORRECTO)
UPDATE app.customer
SET email = regexp_replace(email, '@oldcorp\.com$', '@newcorp.com')
WHERE email LIKE '%@oldcorp.com';  -- ✅ WHERE presente
```

> **Punto clave:** "OPA previene errores humanos antes de que lleguen a producción."

---

## Resumen de Policies Aplicadas

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        OPA POLICIES EN ACCIÓN                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Policy Set: Database_Changes                                              │
│   ════════════════════════════                                              │
│   ├── ✅ Validate changeset structure                                       │
│   ├── ✅ Check rollback exists                                              │
│   └── ✅ Verify author metadata                                             │
│                                                                             │
│   Policy Set: Enforce_SQL_Compliance                                        │
│   ═══════════════════════════════════                                       │
│   ├── ❌ DENY: DROP statements in production                                │
│   ├── ❌ DENY: UPDATE without WHERE clause                                  │
│   ├── ❌ DENY: DELETE without WHERE clause                                  │
│   ├── ❌ DENY: TRUNCATE in production                                       │
│   └── ⚠️  WARN: ALTER TABLE in peak hours                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Pipeline Completo: Flujo de Stages

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    PIPELINE: DB - PostgreSQL                                    │
│                    Trigger: PR en repositorio db-devops-sql                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ╔═══════════════════════════════════════════════════════════════════════════╗ │
│  ║ STAGE 1: Quality Check                     [Trigger: PR Abierto]          ║ │
│  ╠═══════════════════════════════════════════════════════════════════════════╣ │
│  ║                                                                           ║ │
│  ║   ┌─────────────┐     ┌─────────────────────┐                             ║ │
│  ║   │  Semgrep    │     │  Naming Convention  │                             ║ │
│  ║   │  (SAST)     │     │  Check              │     ◄── Ejecutan en        ║ │
│  ║   │             │     │                     │         PARALELO            ║ │
│  ║   └─────────────┘     └─────────────────────┘                             ║ │
│  ║                                                                           ║ │
│  ╚═══════════════════════════════════════════════════════════════════════════╝ │
│                                      │                                          │
│                                      ▼                                          │
│  ╔═══════════════════════════════════════════════════════════════════════════╗ │
│  ║ STAGE 2: DB Validate                       [Trigger: PR Merged]           ║ │
│  ╠═══════════════════════════════════════════════════════════════════════════╣ │
│  ║                                                                           ║ │
│  ║   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ║ │
│  ║   │ Liquibase   │──▶│ Get Change  │──▶│ Get Update  │──▶│ Parse       │   ║ │
│  ║   │ Validate    │   │ (SQL)       │   │ SQL         │   │ Change      │   ║ │
│  ║   │             │   │             │   │             │   │             │   ║ │
│  ║   │ + OPA:      │   │             │   │ + OPA:      │   │             │   ║ │
│  ║   │ Database_   │   │             │   │ Enforce_SQL │   │             │   ║ │
│  ║   │ Changes     │   │             │   │ Compliance  │   │             │   ║ │
│  ║   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   ║ │
│  ║                                                               │           ║ │
│  ║                                                               ▼           ║ │
│  ║                                                    ┌─────────────────┐    ║ │
│  ║                                                    │ JIRA Create     │    ║ │
│  ║                                                    │ Ticket para     │    ║ │
│  ║                                                    │ autorización    │    ║ │
│  ║                                                    └─────────────────┘    ║ │
│  ║                                                                           ║ │
│  ╚═══════════════════════════════════════════════════════════════════════════╝ │
│                                      │                                          │
│                                      ▼                                          │
│  ╔═══════════════════════════════════════════════════════════════════════════╗ │
│  ║ STAGE 3: DB Deploy                         [Trigger: PR Merged]           ║ │
│  ╠═══════════════════════════════════════════════════════════════════════════╣ │
│  ║                                                                           ║ │
│  ║   ┌─────────────────┐       ┌─────────────┐       ┌─────────────────┐     ║ │
│  ║   │ DBSchemaApply   │──────▶│ Wait        │──────▶│ DBSchemaRollback│     ║ │
│  ║   │                 │       │ (10 min)    │       │ (si falla)      │     ║ │
│  ║   │ + OPA:          │       │             │       │                 │     ║ │
│  ║   │ Database_Changes│       │ Ventana de  │       │ rollbackCount:1 │     ║ │
│  ║   │ Enforce_SQL_    │       │ observación │       │                 │     ║ │
│  ║   │ Compliance      │       │             │       │                 │     ║ │
│  ║   └─────────────────┘       └─────────────┘       └─────────────────┘     ║ │
│  ║                                                                           ║ │
│  ╚═══════════════════════════════════════════════════════════════════════════╝ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## ROI y Cierre (3 min)

### Métricas de Impacto

```
┌─────────────────────────────────────────────────────────────────┐
│                    ANTES vs DESPUÉS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Métrica                    Antes          Después             │
│   ═══════════════════════════════════════════════════════════   │
│   Tiempo de deployment       2-4 horas      15 minutos          │
│   Incidentes por cambio DB   1 de 10        1 de 100            │
│   Tiempo de rollback         4-8 horas      2 minutos           │
│   Compliance audit           Manual         100% automático     │
│   Aprobaciones               Email/Slack    JIRA + Pipeline     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Próximos Pasos

```
Semana 1-2    │  POC en ambiente no-prod
              │
Semana 3      │  Definir policies OPA para su contexto
              │
Mes 1         │  Piloto con 1 equipo / 1 base de datos
              │
Mes 2-3       │  Rollout gradual por criticidad
```

---

## Comandos para Demo en Vivo

```bash
# Validar estructura de changelogs
tree changelog/ scripts/

# Mostrar changelog master
cat changelog-master.yaml

# Validar sin ejecutar
liquibase --changeLogFile=changelog-master.yaml validate

# Ver SQL que se ejecutaría
liquibase --changeLogFile=changelog-master.yaml updateSQL

# Ver historia de cambios aplicados
liquibase --changeLogFile=changelog-master.yaml history
```

---

## Estructura de Archivos para Referencia

```
db-devops-sql/
├── changelog-master.yaml          # Orquestador principal
├── changelog/
│   ├── 001-00-init-schema.yaml           # Escenario 1: CREATE
│   ├── 002-00-add-column-customer.yaml   # Escenario 2: ADD COLUMN
│   ├── 003-00-seed-reference-data.yaml   # Escenario 4: INSERT
│   ├── 004-00-drop-column-email.yaml     # Escenario 3: DROP → OPA ❌
│   ├── 004-01-add-column-country_code.yaml
│   ├── 005-00-create-index-email.yaml
│   ├── 006-00-rename-column-name-fullname.yaml
│   ├── 007-00-create-view-customer_country.yaml
│   ├── 008-00-update-customer-email-domain.yaml
│   └── 009-00-dangerous-update-no-where.yaml  # Escenario 5: UPDATE sin WHERE → OPA ❌
├── scripts/
│   ├── ddl/                       # CREATE, ALTER, DROP
│   ├── dml/                       # INSERT, UPDATE
│   └── rollback/                  # Rollback por changeset
└── .harness/
    └── db-pipeline.yaml           # Pipeline de Harness
```
