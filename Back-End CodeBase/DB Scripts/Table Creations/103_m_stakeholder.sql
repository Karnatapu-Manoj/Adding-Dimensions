-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_stakeholder
(
    stakeholder_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stakeholder_code VARCHAR(30) NOT NULL UNIQUE,
    stakeholder_name VARCHAR(200) NOT NULL,
    stakeholder_type VARCHAR(15) DEFAULT 'OTHER' NOT NULL,
    description VARCHAR(500),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
