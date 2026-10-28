CREATE TABLE IF NOT EXISTS public.teacher_auth_tokens
(
    teacher_id integer PRIMARY KEY REFERENCES public.teachers(id) ON DELETE CASCADE,
    token_id varchar(32) NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL
);
