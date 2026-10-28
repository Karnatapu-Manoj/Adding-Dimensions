-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.batch_enrollment
(
    enrollment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    trainee_id BIGINT NOT NULL,
    registration_mode VARCHAR(10) NOT NULL,
    registered_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    registration_link_id BIGINT,
    registered_ip VARCHAR(45),
    trainee_school_id INTEGER,
    trainee_state_id INTEGER,
    trainee_district_id INTEGER,
    trainee_block_id INTEGER,
    trainee_cluster_id INTEGER,
    trainee_school_other VARCHAR(200),
    approval_status VARCHAR(10) DEFAULT 'PENDING' NOT NULL,
    approved_by BIGINT,
    approved_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
