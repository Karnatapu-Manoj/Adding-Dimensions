-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.resource_progress
(
    progress_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trainee_id BIGINT NOT NULL,
    resource_id BIGINT NOT NULL,
    first_viewed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_viewed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_position_seconds INTEGER DEFAULT 0 NOT NULL,
    percent_viewed NUMERIC(5,2) DEFAULT 0 NOT NULL,
    completed_at TIMESTAMPTZ
);
