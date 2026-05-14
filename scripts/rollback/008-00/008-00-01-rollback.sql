-- Restaurar emails desde el backup
UPDATE app.customer c
SET email = b.email
FROM app.customer_email_backup b
WHERE c.id = b.id;

-- (Opcional) limpiar backup si ya no se requiere
-- DROP TABLE IF EXISTS app.customer_email_backup;
