CREATE TABLE IF NOT EXISTS app.country (
    code CHAR(2) PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO app.country (code, name) VALUES
    ('MX', 'Mexico'),
    ('US', 'United States'),
    ('CA', 'Canada')
ON CONFLICT (code) DO NOTHING;
