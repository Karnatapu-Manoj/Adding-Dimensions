-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.user_activity_log
(
    activity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT,
    login_id_tried VARCHAR(30),
    activity_type VARCHAR(20) NOT NULL,
    result VARCHAR(10) NOT NULL,
    ip_address VARCHAR(45),
    occurred_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
