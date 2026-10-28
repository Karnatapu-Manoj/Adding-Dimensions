-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.certificate_template
(
    template_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    template_code VARCHAR(30) NOT NULL UNIQUE,
    project_id INTEGER NOT NULL,
    program_name VARCHAR(200) NOT NULL,
    signatory_name VARCHAR(150) NOT NULL,
    colour_scheme VARCHAR(7) DEFAULT '#17365D' NOT NULL,
    layout VARCHAR(10) DEFAULT 'LANDSCAPE' NOT NULL,
    org_logo_path VARCHAR(500),
    project_logo_path VARCHAR(500),
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
