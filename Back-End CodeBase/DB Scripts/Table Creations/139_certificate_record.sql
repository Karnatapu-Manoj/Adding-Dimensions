-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.certificate_record
(
    certificate_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    certificate_number VARCHAR(40) NOT NULL UNIQUE,
    enrollment_id BIGINT NOT NULL UNIQUE,
    template_id INTEGER NOT NULL,
    trainee_name VARCHAR(150) NOT NULL,
    training_name VARCHAR(200) NOT NULL,
    duration_days SMALLINT NOT NULL,
    completion_date DATE NOT NULL,
    is_provisional BOOLEAN DEFAULT true NOT NULL,
    template_snapshot_json JSONB,
    issued_by BIGINT NOT NULL,
    issued_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
