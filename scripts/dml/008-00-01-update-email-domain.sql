-- Backup previo en tabla temporal
CREATE TABLE IF NOT EXISTS app.customer_email_backup AS
SELECT id, email
FROM app.customer
WHERE email LIKE '%@oldcorp.com';

-- Update de dominio
UPDATE app.customer
SET email = regexp_replace(email, '@oldcorp\.com$', '@newcorp.com')
WHERE email LIKE '%@oldcorp.com';
