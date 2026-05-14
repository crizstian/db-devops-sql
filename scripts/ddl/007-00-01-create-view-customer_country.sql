CREATE OR REPLACE VIEW app.vw_customer_country AS
SELECT
  c.id,
  c.full_name,
  c.email,
  c.country_code,
  c.created_at,
  ct.name AS country_name
FROM app.customer c
LEFT JOIN app.country ct
  ON c.country_code = ct.code;
