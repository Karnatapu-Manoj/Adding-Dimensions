-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.user_access_scope
(
    scope_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    project_id INTEGER,
    state_id INTEGER,
    district_id INTEGER,
    block_id INTEGER,
    cluster_id INTEGER,
    school_id INTEGER,
    valid_from DATE,
    valid_to DATE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
