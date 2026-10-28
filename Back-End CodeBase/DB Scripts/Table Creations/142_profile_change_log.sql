-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.profile_change_log
(
    change_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    field_name VARCHAR(30) NOT NULL,
    old_value_masked VARCHAR(150),
    new_value_masked VARCHAR(150),
    changed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
