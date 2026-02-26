ALTER TABLE app.customer
ADD COLUMN email TEXT;

COMMENT ON COLUMN app.customer.email IS 'Customer email address (nullable during POC)';
