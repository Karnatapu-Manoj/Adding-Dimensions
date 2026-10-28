-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.data_subject_request
(
    request_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trainee_id BIGINT NOT NULL,
    request_type VARCHAR(12) NOT NULL,
    details VARCHAR(1000),
    status VARCHAR(12) DEFAULT 'OPEN' NOT NULL,
    received_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    due_at DATE,
    handled_by BIGINT,
    closed_at TIMESTAMPTZ,
    resolution VARCHAR(1000)
);
