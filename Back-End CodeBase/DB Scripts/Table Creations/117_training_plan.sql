-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.training_plan
(
    plan_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id INTEGER NOT NULL,
    plan_code VARCHAR(30) NOT NULL UNIQUE,
    plan_name VARCHAR(200) NOT NULL,
    training_type VARCHAR(15) NOT NULL,
    total_days SMALLINT NOT NULL,
    description VARCHAR(1000),
    status VARCHAR(10) DEFAULT 'DRAFT' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
