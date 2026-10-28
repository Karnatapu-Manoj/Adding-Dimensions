-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.completion_review
(
    completion_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id BIGINT NOT NULL UNIQUE,
    attendance_pct NUMERIC(5,2),
    assessment_score NUMERIC(5,2),
    is_eligible BOOLEAN DEFAULT false NOT NULL,
    remarks VARCHAR(300),
    reviewed_by BIGINT NOT NULL,
    reviewed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
