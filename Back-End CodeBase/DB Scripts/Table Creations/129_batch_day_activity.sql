-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.batch_day_activity
(
    batch_activity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_day_id BIGINT NOT NULL,
    seq_no SMALLINT NOT NULL,
    activity_type VARCHAR(12) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    start_time TIME,
    duration_minutes SMALLINT,
    resource_id BIGINT
);
