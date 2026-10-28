-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.training_batch
(
    batch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_code VARCHAR(30) NOT NULL UNIQUE,
    project_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    school_id INTEGER NOT NULL,
    reference_location VARCHAR(300),
    actual_location VARCHAR(300),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    capacity INTEGER NOT NULL,
    trainer_id INTEGER NOT NULL,
    open_registration BOOLEAN DEFAULT false NOT NULL,
    is_closed BOOLEAN DEFAULT false NOT NULL,
    closed_at TIMESTAMPTZ,
    plan_code_snapshot VARCHAR(30),
    plan_snapshot_json JSONB,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
