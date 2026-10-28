-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.plan_resource_link
(
    link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    resource_id BIGINT NOT NULL,
    project_id INTEGER,
    apply_existing BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
