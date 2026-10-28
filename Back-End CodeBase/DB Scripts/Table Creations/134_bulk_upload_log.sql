-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.bulk_upload_log
(
    upload_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    upload_type VARCHAR(20) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    project_id INTEGER,
    batch_id BIGINT,
    total_rows INTEGER DEFAULT 0 NOT NULL,
    success_rows INTEGER DEFAULT 0 NOT NULL,
    failed_rows INTEGER DEFAULT 0 NOT NULL,
    status VARCHAR(10) DEFAULT 'VALIDATED' NOT NULL,
    error_report_path VARCHAR(500),
    uploaded_by BIGINT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
