ALTER TABLE app.customer
ADD COLUMN country_code CHAR(2);

COMMENT ON COLUMN app.customer.country_code IS 'FK to app.country - customer country of residence';
