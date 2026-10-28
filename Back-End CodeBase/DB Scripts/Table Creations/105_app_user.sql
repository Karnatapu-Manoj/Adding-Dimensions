-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.app_user
(
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login_id VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    role_id SMALLINT NOT NULL,
    email_enc BYTEA,
    email_hash CHAR(64),
    email_mask VARCHAR(150),
    pii_key_version SMALLINT DEFAULT 1 NOT NULL,
    mobile_enc BYTEA,
    mobile_hash CHAR(64),
    mobile_mask VARCHAR(150),
    password_hash VARCHAR(255) NOT NULL,
    must_change_password BOOLEAN DEFAULT true NOT NULL,
    failed_login_count SMALLINT DEFAULT 0 NOT NULL,
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    stakeholder_id INTEGER,
    parent_user_id BIGINT,
    trainer_id INTEGER,
    trainee_id BIGINT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
