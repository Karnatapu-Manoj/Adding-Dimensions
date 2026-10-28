-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_block
(
    block_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    district_id INTEGER NOT NULL,
    block_code VARCHAR(10),
    block_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
