-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.system_setting
(
    setting_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id INTEGER UNIQUE,
    attendance_threshold_pct NUMERIC(5,2),
    pass_score NUMERIC(5,2),
    assessment_required BOOLEAN,
    feedback_required BOOLEAN,
    registration_window VARCHAR(12) DEFAULT 'DAY1' NOT NULL,
    trainer_upload_allowed BOOLEAN DEFAULT false NOT NULL,
    propagate_resources BOOLEAN DEFAULT false NOT NULL,
    restrict_venue_to_scope BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
