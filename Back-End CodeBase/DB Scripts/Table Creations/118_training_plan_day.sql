-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.training_plan_day
(
    plan_day_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    day_no SMALLINT NOT NULL,
    day_title VARCHAR(200) NOT NULL,
    objective VARCHAR(500),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
