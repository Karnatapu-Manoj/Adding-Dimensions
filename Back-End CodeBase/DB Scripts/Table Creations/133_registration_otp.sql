-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.registration_otp
(
    otp_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    mobile_enc BYTEA,
    mobile_hash CHAR(64),
    mobile_mask VARCHAR(150),
    email_enc BYTEA,
    email_hash CHAR(64),
    email_mask VARCHAR(150),
    pii_key_version SMALLINT DEFAULT 1 NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempt_count SMALLINT DEFAULT 0 NOT NULL,
    verified_at TIMESTAMPTZ
);
