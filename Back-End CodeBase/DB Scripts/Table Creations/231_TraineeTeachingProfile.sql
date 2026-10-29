ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS school_id integer REFERENCES public.m_school(school_id);
ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS gender varchar(30);
ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS designation varchar(80);
ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS classes_taught jsonb NOT NULL DEFAULT '[]';
ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS subjects_taught jsonb NOT NULL DEFAULT '[]';
ALTER TABLE public.trainee ADD COLUMN IF NOT EXISTS teaching_experience varchar(50);

ALTER TABLE public.assessment_attempt ADD COLUMN IF NOT EXISTS rating_score numeric;
ALTER TABLE public.assessment_attempt ADD COLUMN IF NOT EXISTS rating_max_marks numeric;
