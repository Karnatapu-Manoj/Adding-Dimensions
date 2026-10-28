-- BRD v2 extensions to the workbook: reusable plans, project phases/plan links,
-- application sessions, assessment attempts, and frontend identifier compatibility.
ALTER TABLE public.training_plan ALTER COLUMN project_id DROP NOT NULL;

CREATE TABLE IF NOT EXISTS public.project_phase (
    phase_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id integer NOT NULL REFERENCES public.project(project_id),
    phase_name varchar(200) NOT NULL, sequence_number integer NOT NULL,
    start_date date NOT NULL, end_date date NOT NULL, status varchar(20) NOT NULL,
    CHECK (end_date >= start_date)
);
CREATE TABLE IF NOT EXISTS public.project_plan_association (
    association_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id integer NOT NULL REFERENCES public.project(project_id),
    plan_id integer NOT NULL REFERENCES public.training_plan(plan_id),
    is_active boolean NOT NULL DEFAULT true,
    UNIQUE (project_id, plan_id)
);
CREATE TABLE IF NOT EXISTS public.odoo_project_catalog (
    catalog_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference varchar(50) NOT NULL UNIQUE, project_name varchar(200) NOT NULL,
    sponsor_name varchar(200) NOT NULL
);
CREATE TABLE IF NOT EXISTS public.assessment_attempt (
    attempt_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id bigint NOT NULL REFERENCES public.batch_enrollment(enrollment_id),
    resource_id bigint NOT NULL REFERENCES public.learning_resource(resource_id),
    kind varchar(20) NOT NULL, answers jsonb NOT NULL DEFAULT '{}',
    score numeric(7,2), max_marks numeric(7,2), passed boolean,
    submitted_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.attendance_exclusion (
    exclusion_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id bigint NOT NULL REFERENCES public.batch_enrollment(enrollment_id),
    training_date date NOT NULL, reason varchar(1000) NOT NULL,
    approved boolean NOT NULL DEFAULT true, changed_by bigint NOT NULL REFERENCES public.app_user(user_id)
);
CREATE TABLE IF NOT EXISTS public.external_course_record (
    record_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id bigint NOT NULL REFERENCES public.batch_enrollment(enrollment_id),
    course_name varchar(200) NOT NULL, completed boolean NOT NULL DEFAULT false
);
CREATE TABLE IF NOT EXISTS public.school_eligibility (
    eligibility_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    school_id integer NOT NULL REFERENCES public.m_school(school_id),
    project_id integer REFERENCES public.project(project_id),
    beneficiary_type varchar(20) NOT NULL, eligible_count integer NOT NULL DEFAULT 0,
    CHECK (eligible_count >= 0)
);
CREATE TABLE IF NOT EXISTS public.portal_setting (
    portal_setting_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    setting_key varchar(100) NOT NULL
);
CREATE TABLE IF NOT EXISTS public.app_auth_session (
    user_id bigint PRIMARY KEY REFERENCES public.app_user(user_id),
    token_id varchar(32) NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL, role_code varchar(30) NOT NULL
);
CREATE TABLE IF NOT EXISTS public.portal_collection (
    collection_key varchar(100) PRIMARY KEY,
    table_name name NOT NULL, pk_column name NOT NULL,
    read_roles text[] NOT NULL, write_roles text[] NOT NULL
);

DO $migration$
DECLARE target record;
BEGIN
    FOR target IN SELECT table_name FROM information_schema.tables
        WHERE table_schema='public' AND table_type='BASE TABLE'
          AND table_name NOT IN ('portal_collection','app_auth_session','teachers','teacher_auth_tokens')
    LOOP
        EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS external_id varchar(100), '
            'ADD COLUMN IF NOT EXISTS ui_data jsonb NOT NULL DEFAULT ''{}'', '
            'ADD COLUMN IF NOT EXISTS portal_collection varchar(100), '
            'ADD COLUMN IF NOT EXISTS portal_project_id integer REFERENCES public.project(project_id), '
            'ADD COLUMN IF NOT EXISTS portal_owner_user_id bigint REFERENCES public.app_user(user_id), '
            'ADD COLUMN IF NOT EXISTS portal_batch_id bigint REFERENCES public.training_batch(batch_id), '
            'ADD COLUMN IF NOT EXISTS row_version bigint NOT NULL DEFAULT 1, '
            'ADD COLUMN IF NOT EXISTS portal_deleted boolean NOT NULL DEFAULT false', target.table_name);
        EXECUTE format('CREATE UNIQUE INDEX IF NOT EXISTS %I ON public.%I (external_id)',
            'ux_portal_'||target.table_name||'_external',target.table_name);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I (portal_project_id,portal_collection) WHERE NOT portal_deleted',
            'ix_portal_'||target.table_name||'_scope',target.table_name);
    END LOOP;
END;
$migration$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_attendance_enrollment_date ON public.attendance(enrollment_id,attendance_date);
CREATE UNIQUE INDEX IF NOT EXISTS ux_enrollment_batch_trainee ON public.batch_enrollment(batch_id,trainee_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_plan_day_number ON public.training_plan_day(plan_id,day_no);
CREATE UNIQUE INDEX IF NOT EXISTS ux_batch_day_number ON public.batch_day(batch_id,day_no);
CREATE INDEX IF NOT EXISTS ix_portal_session_expiry ON public.app_auth_session(expires_at);
