-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.role_creation_rule
(
    rule_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    creator_role_id SMALLINT NOT NULL,
    creatable_role_id SMALLINT NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
