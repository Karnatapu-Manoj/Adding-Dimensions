-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.batch_registration_link
(
    link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    max_registrations INTEGER,
    registration_count INTEGER DEFAULT 0 NOT NULL,
    scan_count INTEGER DEFAULT 0 NOT NULL,
    is_revoked BOOLEAN DEFAULT false NOT NULL,
    revoked_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
