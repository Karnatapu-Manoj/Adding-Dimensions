-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_school
(
    school_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    udise_code VARCHAR(20) NOT NULL UNIQUE,
    school_name VARCHAR(200) NOT NULL,
    state_id INTEGER NOT NULL,
    district_id INTEGER NOT NULL,
    block_id INTEGER,
    cluster_id INTEGER,
    actual_location VARCHAR(300),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
