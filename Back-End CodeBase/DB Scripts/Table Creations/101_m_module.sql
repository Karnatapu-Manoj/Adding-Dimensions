-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_module
(
    module_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module_code VARCHAR(40) NOT NULL UNIQUE,
    module_name VARCHAR(80) NOT NULL,
    sort_order SMALLINT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
