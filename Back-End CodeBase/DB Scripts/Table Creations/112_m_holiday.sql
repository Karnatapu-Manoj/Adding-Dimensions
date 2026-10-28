-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.m_holiday
(
    holiday_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    holiday_name VARCHAR(150) NOT NULL,
    holiday_date DATE NOT NULL,
    scope VARCHAR(10) NOT NULL,
    state_id INTEGER,
    district_id INTEGER,
    project_id INTEGER,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
