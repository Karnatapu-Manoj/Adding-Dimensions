-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_pii_field
(
    pii_field_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    field_code VARCHAR(50) NOT NULL UNIQUE,
    table_name VARCHAR(50) NOT NULL,
    column_base VARCHAR(50) NOT NULL,
    mask_rule VARCHAR(15) NOT NULL,
    description VARCHAR(200),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
