CREATE TABLE IF NOT EXISTS public.teachers
(
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    email varchar(254) NOT NULL,
    password_hash text NOT NULL,
    subject varchar(150) NOT NULL DEFAULT '',
    phone_number varchar(30) NOT NULL DEFAULT '',
    role varchar(20) NOT NULL DEFAULT 'Teacher' CHECK (role IN ('Teacher', 'Admin')),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_teachers_email ON public.teachers (lower(email));
