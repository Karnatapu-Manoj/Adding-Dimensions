-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.form_submission
(
    submission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    submitted_on DATE DEFAULT CURRENT_DATE NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    answer VARCHAR(1000) NOT NULL,
    score NUMERIC(5,2)
);
