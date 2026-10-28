-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.role_pii_permission
(
    role_pii_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id SMALLINT NOT NULL,
    pii_field_id SMALLINT NOT NULL,
    view_mode VARCHAR(6) DEFAULT 'MASKED' NOT NULL,
    can_export_full BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
