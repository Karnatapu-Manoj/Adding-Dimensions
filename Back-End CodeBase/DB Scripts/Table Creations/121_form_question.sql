-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.form_question
(
    question_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    resource_id BIGINT NOT NULL,
    question_text VARCHAR(1000) NOT NULL,
    expected_answer VARCHAR(500),
    options_json JSONB,
    marks NUMERIC(5,2) DEFAULT 100 NOT NULL,
    sort_order SMALLINT DEFAULT 1 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
