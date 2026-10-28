-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.learning_resource
(
    resource_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    resource_code VARCHAR(30) NOT NULL UNIQUE,
    resource_name VARCHAR(200) NOT NULL,
    resource_type VARCHAR(10) NOT NULL,
    project_id INTEGER,
    is_common BOOLEAN DEFAULT false NOT NULL,
    common_requested BOOLEAN DEFAULT false NOT NULL,
    file_name VARCHAR(255),
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    storage_path VARCHAR(500),
    form_type VARCHAR(12),
    form_purpose VARCHAR(30),
    duration_seconds INTEGER,
    access_mode VARCHAR(10) DEFAULT 'PLAN_ONLY' NOT NULL,
    uploaded_by BIGINT NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
