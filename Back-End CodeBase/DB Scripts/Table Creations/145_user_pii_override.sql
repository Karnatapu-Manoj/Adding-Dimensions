-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.user_pii_override
(
    override_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    pii_field_id SMALLINT NOT NULL,
    view_mode VARCHAR(6) NOT NULL,
    reason VARCHAR(300) NOT NULL,
    valid_from DATE,
    valid_to DATE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
