-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.pii_access_log
(
    pii_access_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    pii_field_id SMALLINT NOT NULL,
    entity_id VARCHAR(50) NOT NULL,
    action VARCHAR(12) NOT NULL,
    purpose VARCHAR(200),
    ip_address VARCHAR(45),
    occurred_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
