CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.customer (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE app.customer IS 'Customer master table for application POC';
COMMENT ON COLUMN app.customer.name IS 'Customer display name';
