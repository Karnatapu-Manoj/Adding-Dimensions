-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_district
(
    district_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    state_id INTEGER NOT NULL,
    district_code VARCHAR(10),
    district_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
