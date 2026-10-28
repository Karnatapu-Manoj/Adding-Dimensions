-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.trainer
(
    trainer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trainer_code VARCHAR(30) NOT NULL UNIQUE,
    trainer_name VARCHAR(150) NOT NULL,
    category VARCHAR(12) NOT NULL,
    mobile_enc BYTEA,
    mobile_hash CHAR(64),
    mobile_mask VARCHAR(150),
    email_enc BYTEA,
    email_hash CHAR(64),
    email_mask VARCHAR(150),
    pii_key_version SMALLINT DEFAULT 1 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
