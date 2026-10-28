-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.batch_day
(
    batch_day_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    day_no SMALLINT NOT NULL,
    day_date DATE NOT NULL,
    day_title VARCHAR(200) NOT NULL,
    objective VARCHAR(500)
);
